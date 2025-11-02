<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Requests\FaceEnrollRequest;
use App\Http\Requests\FaceMatchRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;

class FaceController extends Controller
{
    // 🎨 HÀM ENROLL (ĐÃ SỬA LỖI 500)
    public function enroll(Request $r)
    {
        try {
            // 1. Chỉ validate file ảnh
            $data = $r->validate([
                'template_base64' => 'required|string',
            ]);

            $user = $r->user();
            $student = $user->student ?? null;
            if (!$student) {
                return response()->json(['error' => 'Student profile not found'], 400);
            }

            // 2. Chuyển file 'face_image' sang base64
            $base64String = $data['template_base64'];

            // 3. 🎨 SỬA LỖI: (Sửa theo các lỗi trước)
            // Chỉ chèn các cột CÓ TỒN TẠI
            try {
                $id = DB::table('face_templates_simple')->insertGetId([
                    'student_id'    => $student->id,
                    'template'      => $base64String, // Lưu base64 text
                    'created_at'    => Carbon::now(),
                ]);

            } catch (\Illuminate\Database\QueryException $e) {
                // Xử lý dự phòng (nếu cột 'created_at' cũng không có)
                if (str_contains($e->getMessage(), 'Unknown column \'created_at\'')) {
                    $id = DB::table('face_templates_simple')->insertGetId([
                        'student_id'    => $student->id,
                        'template'      => $base64String,
                    ]);
                } else {
                    throw $e; // Báo lỗi SQL khác
                }
            }

            // 4. 🎨 ĐÃ XÓA 2 DÒNG GÂY LỖI:
            // $user->face_image_path = 'registered';
            // $user->save();

            // 5. Trả về thành công
            return response()->json([
                'success' => true,
                'message' => 'Đăng ký khuôn mặt thành công.',
                'face_template_id' => $id
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['error' => collect($e->errors())->flatten()->first()], 422);
        } catch (\Throwable $e) {
            \Log::error('Register face error: ' . $e->getMessage());
            return response()->json(['error' => 'Lỗi server khi xử lý ảnh'], 500);
        }
    }

    // (Hàm logMatch giữ nguyên...)
    public function logMatch(FaceMatchRequest $r)
    {
        // (Code của bạn... không thay đổi)
        $spoof = $r->input('spoof_flags');
        if (is_string($spoof)) {
            $spoof = json_decode($spoof, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                $spoof = null;
            }
        }
        $id = DB::table('face_matches')->insertGetId([
            'attendance_session_id' => $r->input('attendance_session_id'),
            'student_id'            => $r->input('student_id'),
            'face_template_id'      => $r->input('face_template_id'),
            'method'                => $r->input('method'),
            'similarity'            => $r->input('similarity'),
            'threshold'             => $r->input('threshold'),
            'decision'              => $r->input('decision'),
            'liveness_type'         => $r->input('liveness_type', 'none'),
            'liveness_score'        => $r->input('liveness_score'),
            'spoof_flags'           => $spoof ? json_encode($spoof) : null,
            'model_version'         => $r->input('model_version'),
            'image_path'            => $r->input('image_path'),
            'created_at'            => now(),
        ]);
        return response()->json(['face_match_id' => $id], 201);
    }
}
