<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Kreait\Firebase\Factory;

class FirebaseBridgeController extends Controller
{
    /**
     * POST /api/firebase/token/login
     * Body: { email, password }
     * - Xác thực bằng Laravel (MySQL)
     * - Trả về firebase custom token + thông tin user Laravel
     */
    public function loginAndIssueToken(Request $request)
    {
        $data = $request->validate([
            'email'    => ['required','email'],
            'password' => ['required','string'],
        ]);

        if (!Auth::attempt($data)) {
            throw ValidationException::withMessages(['email' => 'Invalid credentials']);
        }

        /** @var \App\Models\User $user */
        $user = Auth::user();

        // UID thống nhất giữa Laravel và Firebase: dùng prefix + id Laravel
        $uid = 'laravel-' . $user->id;

        $factory = (new Factory())
            ->withServiceAccount(config('services.firebase.credentials'));

        if (config('services.firebase.project_id')) {
            $factory = $factory->withProjectId(config('services.firebase.project_id'));
        }

        $auth = $factory->createAuth();

        // Custom claims đưa role vào ID token
        $additionalClaims = [
            'role' => $user->role, // admin|teacher|student
            'email' => $user->email,
        ];

        // Tạo custom token (Firebase sẽ tự tạo user nếu uid chưa tồn tại khi client signInWithCustomToken)
        $customToken = $auth->createCustomToken($uid, $additionalClaims)->toString();

        // (Tùy chọn) Nếu muốn set "persistent" custom claims cho user ở server:
        // try { $auth->setCustomUserClaims($uid, ['role' => $user->role]); } catch (\Throwable $ignore) {}

        return response()->json([
            'firebase_token' => $customToken,
            'uid'   => $uid,
            'user'  => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'role'  => $user->role,
            ],
        ]);
    }

    /**
     * POST /api/firebase/token
     * - Dành cho client đã login Laravel (Bearer JWT) → chỉ phát token Firebase
     */
    public function issueTokenForCurrent(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        $uid = 'laravel-' . $user->id;

        $factory = (new Factory())
            ->withServiceAccount(config('services.firebase.credentials'));

        if (config('services.firebase.project_id')) {
            $factory = $factory->withProjectId(config('services.firebase.project_id'));
        }

        $auth = $factory->createAuth();

        $additionalClaims = [
            'role'  => $user->role,
            'email' => $user->email,
        ];

        $customToken = $auth->createCustomToken($uid, $additionalClaims)->toString();

        return response()->json([
            'firebase_token' => $customToken,
            'uid'   => $uid,
        ]);
    }
}
