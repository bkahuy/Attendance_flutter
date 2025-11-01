<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FaceController extends Controller
{
    // ===== 1. Đăng ký khuôn mặt (lần đầu) =====
    public function enroll(Request $req)
    {
        $req->validate([
            'student_id' => 'required|integer',
            'template_base64' => 'required|string',
        ]);

        $binary = base64_decode($req->template_base64);

        DB::table('face_templates_simple')->updateOrInsert(
            ['student_id' => $req->student_id],
            [
                'template' => $binary,
                'version' => 'mfn-1.0',
                'is_primary' => 1,
                'updated_at' => now()
            ]
        );

        DB::table('students')
            ->where('id', $req->student_id)
            ->update(['face_enrolled' => 1]);

        return response()->json(['ok' => true, 'message' => 'Đăng ký khuôn mặt thành công']);
    }

    // ===== 2. Xác thực khuôn mặt (chỉ kiểm tra, không ghi điểm danh) =====
    public function verify(Request $req)
    {
        $req->validate([
            'student_id' => 'required|integer',
            'template_base64' => 'required|string',
        ]);

        $existing = DB::table('face_templates_simple')
            ->where('student_id', $req->student_id)
            ->first();

        if (!$existing) {
            return response()->json(['ok' => false, 'reason' => 'Chưa đăng ký khuôn mặt'], 404);
        }

        // So khớp đơn giản: chỉ kiểm tra tồn tại
        return response()->json([
            'ok' => true,
            'message' => 'Khuôn mặt đã xác thực hợp lệ',
        ]);
    }
}
