<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class AuthController extends Controller
{
    // Flutter login (teacher/student)
    public function login(Request $request)
    {
        try {
            $data = $request->validate([
                'email'    => ['required','email'],
                'password' => ['required','string'],
            ]);

            // Pre-check: user phải tồn tại và thuộc role cho phép
            $user = User::where('email', $data['email'])->first();
            if (!$user || !in_array($user->role, ['teacher','student'], true)) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }
            // (Optional) khóa theo trạng thái
            // if (($user->status ?? 'active') !== 'active') {
            //     return response()->json(['error' => 'Account disabled'], 403);
            // }

            // Thử cấp token
            if (!$token = auth('api')->attempt($data)) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }

            return response()->json([
                'access_token' => $token,
                'token_type'   => 'Bearer',
                'expires_in'   => auth('api')->factory()->getTTL() * 60, // giây
                'user'         => $user->only(['id','name','email','role']),
            ], 200);

        } catch (\Throwable $e) {
            \Log::error('Login error: '.$e->getMessage(), ['trace'=>$e->getTraceAsString()]);
            return response()->json(['error'=>'Server error'], 500);
        }
    }

    // Lấy profile bằng token
    public function profile(Request $request)
    {
        return response()->json(auth('api')->user());
    }

    // Refresh JWT (tuỳ app bạn có dùng không)
    public function refresh()
    {
        try {
            $new = auth('api')->refresh(); // cần enable blacklist trong jwt config nếu muốn revoke
            return response()->json([
                'access_token' => $new,
                'token_type'   => 'Bearer',
                'expires_in'   => auth('api')->factory()->getTTL() * 60,
            ]);
        } catch (\Throwable $e) {
            return response()->json(['error'=>'Unauthorized'], 401);
        }
    }

    // Logout (invalidate token hiện tại)
    public function logout()
    {
        try {
            auth('api')->logout();
        } catch (\Throwable $e) {}
        return response()->json(['ok'=>true]);
    }
}
