<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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

            $user = User::where('email', $data['email'])->first();
            if (!$user || !in_array($user->role, ['teacher','student'], true)) {
                return response()->json(['error' => 'Thông tin đăng nhập không hợp lệ'], 401);
            }

            if (!$token = auth('api')->attempt($data)) {
                return response()->json(['error' => 'Thông tin đăng nhập không hợp lệ'], 401);
            }

            // 🎨 BƯỚC 1: THAY ĐỔI LOGIC KIỂM TRA KHUÔN MẶT
            $requiresFace = false; // Mặc định là false

            if ($user->role === 'student') {
                // Lấy student profile (giả sử bạn đã định nghĩa 'student' relationship trong User model)
                $student = $user->student;

                if ($student) {
                    // Kiểm tra xem có bản ghi nào trong 'face_templates_simple' không
                    $hasTemplate = DB::table('face_templates_simple')
                        ->where('student_id', $student->id)
                        ->exists();

                    if (!$hasTemplate) {
                        $requiresFace = true; // 👈 BẮT ĐĂNG KÝ
                    }
                } else {
                    \Log::warning('User ' . $user->id . ' có role student nhưng không tìm thấy student profile.');
                }
            }
            // --- Kết thúc BƯỚC 1 ---


            return response()->json([
                'access_token' => $token,
                'token_type'   => 'Bearer',
                'expires_in'   => auth('api')->factory()->getTTL() * 60,
                'user'         => $user->only(['id','name','email','role']),

                // 🎨 BƯỚC 2: Thêm cờ (flag) này vào JSON trả về
                'requires_face_registration' => $requiresFace,

            ], 200);

        } catch (\Throwable $e) {
            \Log::error('Login error: '.$e->getMessage(), ['trace'=>$e->getTraceAsString()]);
            return response()->json(['error'=>'Server error'], 500);
        }
    }

    // (Các hàm khác: profile, refresh, logout, changePassword... giữ nguyên)

    public function profile(Request $request)
    {
        return response()->json(auth('api')->user());
    }

    public function refresh()
    {
        try {
            $new = auth('api')->refresh();
            return response()->json([
                'access_token' => $new,
                'token_type'   => 'Bearer',
                'expires_in'   => auth('api')->factory()->getTTL() * 60,
            ]);
        } catch (\Throwable $e) {
            return response()->json(['error'=>'Unauthorized'], 401);
        }
    }

    public function logout()
    {
        try {
            auth('api')->logout();
        } catch (\Throwable $e) {}
        return response()->json(['ok'=>true]);
    }

    public function changePassword(Request $request)
    {
        try {
            $data = $request->validate([
                'email'        => ['required', 'string'],
                'old_password'     => ['required', 'string'],
                'new_password'     => ['required', 'string', 'min:6'],
                'confirm_password' => ['required', 'same:new_password'],
            ]);
            $user = DB::table('users')->where('email', $data['email'])->first();
            if (!$user) {
                return response()->json(['error' => 'Email người dùng không tồn tại'], 404);
            }
            if (!Hash::check($data['old_password'], $user->password)) {
                return response()->json(['error' => 'Mật khẩu cũ không chính xác'], 401);
            }
            DB::table('users')
                ->where('email', $data['email'])
                ->update([
                    'password' => Hash::make($data['new_password']),
                    'updated_at' => now(), // nếu có cột updated_at
                ]);
            return response()->json(['message' => 'Đổi mật khẩu thành công'], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['error' => collect($e->errors())->flatten()->first()], 422);
        } catch (\Throwable $e) {
            \Log::error('Change password error: ' . $e->getMessage());
            return response()->json(['error' => 'Server error'], 500);
        }
    }
}
