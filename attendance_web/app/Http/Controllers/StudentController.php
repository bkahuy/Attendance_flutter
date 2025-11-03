<?php

namespace App\Http\Controllers;

use App\Models\{Student, ClassSection, Schedule, AttendanceSession, AttendanceRecord};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http; // 🎨 1. THÊM IMPORT NÀY
use Illuminate\Support\Facades\Log;

class StudentController extends Controller
{
    /**
     * 📅 Lấy lịch học (schedule)
     */
    public function schedule(Request $request)
    {
        // 1. Lấy ngày và thông tin sinh viên
        $date = $request->input('date') ?? now()->toDateString();
        $user = auth('api')->user();
        $student = Student::where('user_id', $user->id)->firstOrFail();

        // 2. Chuyển đổi thứ
        $carbonDate = Carbon::parse($date);
        $carbonWeekday = $carbonDate->dayOfWeek;
        $weekday = ($carbonWeekday === 0) ? 6 : $carbonWeekday - 1;

        // 3. Thực thi truy vấn SQL
        $sql = "
            SELECT
                sc.class_section_id,
                sc.course_code,
                sc.course_name,
                sc.room,
                sc.start_time,
                sc.end_time
            FROM
                vw_student_schedule sc
            WHERE
                sc.student_id = ?
                AND sc.weekday = ?
                AND sc.start_date <= ?
                AND sc.end_date >= ?
            ORDER BY
                sc.start_time;
        ";

        $schedules = DB::select($sql, [
            $student->id,
            $weekday,
            $date,
            $date
        ]);

        // 4. Biến đổi dữ liệu (mapping) - FIX LỆCH GIỜ CUỐI CÙNG
        $formattedSchedules = collect($schedules)->map(function ($schedule) use ($carbonDate) {

            // Lấy chuỗi ngày và giờ thuần
            $dateTimeString = $carbonDate->toDateString() . ' ' . $schedule->start_time;
            $endDateTimeString = $carbonDate->toDateString() . ' ' . $schedule->end_time;

            // 🐛 FIX CUỐI CÙNG: Dùng createFromFormat để ép múi giờ NGUỒN là UTC (Giả định của CSDL)
            // Sau đó, chuyển nó sang múi giờ ĐÍCH (VN).

            // Đối tượng Carbon (tạm thời) dựa trên chuỗi ngày/giờ:
            $tempStart = Carbon::createFromFormat('Y-m-d H:i:s', $dateTimeString, 'UTC');
            $tempEnd = Carbon::createFromFormat('Y-m-d H:i:s', $endDateTimeString, 'UTC');

            // Chuyển đối tượng từ UTC sang múi giờ App (VN)
            $startDateTime = $tempStart->setTimezone(config('app.timezone'));
            $endDateTime = $tempEnd->setTimezone(config('app.timezone'));


            return [
                'class_section_id' => $schedule->class_section_id,
                'course_code' => $schedule->course_code,
                'course_name' => $schedule->course_name,
                'class_name'  => $schedule->course_name,
                'room'        => $schedule->room,

                // 🐛 TRẢ VỀ ISO8601 STRING: Flutter sẽ nhận 08:00:00+07:00
                'start_time'  => $startDateTime->toIso8601String(),
                'end_time'    => $endDateTime->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $formattedSchedules,
        ]);
    }


    /**
     * 📸 Xử lý check-in (checkIn)
     */
    public function checkIn(Request $r)
    {
        $data = $r->validate([
            'attendance_session_id' => 'required|exists:attendance_sessions,id',
            'status' => 'required|in:present,late,absent',
            'template_base64' => 'required|string',
            'gps_lat' => 'nullable|numeric',
            'gps_lng' => 'nullable|numeric',
            'password' => 'nullable|string',
        ]);

        $user = auth('api')->user();
        $student = Student::where('user_id', $user->id)->firstOrFail();
        $session = AttendanceSession::findOrFail($data['attendance_session_id']);

        // 2. Tạm thời vô hiệu hóa kiểm tra thời gian (nếu bạn vẫn đang test)
        // if (now()->lt($session->start_at) || now()->gt($session->end_at)) {
        //     return response()->json(['error' => 'Session is not active'], 400);
        // }

        $flags = $session->mode_flags ?? [];
        if (!empty($flags['password']) && $session->password_hash) {
            if (empty($data['password']) || !Hash::check($data['password'], $session->password_hash)) {
                return response()->json(['error' => 'Invalid password'], 400);
            }
        }

        // 3. 🎨 THAY THẾ LOGIC "GIẢ LẬP"

        // 3a. Lấy template ĐÃ LƯU
        $savedTemplate = DB::table('face_templates_simple')
            ->where('student_id', $student->id)
            ->orderBy('created_at', 'desc')
            ->first();

        if (!$savedTemplate) {
            return response()->json(['error' => 'Khuôn mặt của bạn chưa được đăng ký.'], 404);
        }

        // 3b. Lấy template MỚI
        $newTemplateBase64 = $data['template_base64'];

        // 3c. 🎨 GỌI API SO SÁNH (THAY VÌ $isMatch = true)

        // ‼️ Đổi IP này thành địa chỉ server Python của bạn
        $aiServiceUrl = 'http://127.0.0.1:5001/match-faces';
        $isMatch = false; // Mặc định là KHÔNG KHỚP

        try {
            $response = Http::post($aiServiceUrl, [
                'template1_base64' => $savedTemplate->template, // Lấy từ DB
                'template2_base64' => $newTemplateBase64,      // Lấy từ App
            ]);

            // Kiểm tra xem AI service có chạy thành công VÀ có khớp không
            if ($response->successful() && $response->json('is_match') === true) {
                $isMatch = true;
                Log::info('Face match SUCCESS for student ' . $student->id . ': ' . $response->json('similarity'));
            } else {
                Log::warning('Face match FAILED for student ' . $student->id . ': ' . $response->body());
            }

        } catch (\Exception $e) {
            // Lỗi nếu không kết nối được service Python (ví dụ: 127.0.0.1:5001 bị tắt)
            Log::error('AI Service connection error: ' . $e->getMessage());
            return response()->json(['error' => 'Lỗi dịch vụ AI: Không thể so sánh khuôn mặt.'], 500);
        }
        // --- KẾT THÚC PHẦN SỬA ---

        if (!$isMatch) {
            return response()->json(['error' => 'Khuôn mặt không khớp. Vui lòng thử lại.'], 400);
        }

        // 4. 🎨 SỬA LẠI: Ghi record (KHÔNG cần lưu ảnh)
        $rec = AttendanceRecord::updateOrCreate(
            ['attendance_session_id' => $session->id, 'student_id' => $student->id],
            [
                'status' => $data['status'],
                'photo_path' => null, // 👈 Không lưu ảnh nữa
                'gps_lat' => $data['gps_lat'] ?? null,
                'gps_lng' => $data['gps_lng'] ?? null,
                'created_at' => now(),
            ]
        );

        return response()->json(['message' => 'Checked in', 'record' => $rec]);
    }

    /**
     * Lấy lịch sử điểm danh (attendanceHistory)
     */
    public function attendanceHistory(Request $request, $classSectionId)
    {
        $user = auth('api')->user();
        $student = Student::where('user_id', $user->id)->firstOrFail();
        $sessions = AttendanceSession::where('class_section_id', $classSectionId)
            ->orderBy('start_at', 'asc')
            ->get();
        $history = $sessions->map(function ($session) use ($student) {
            $record = $session->records()->where('student_id', $student->id)->first();
            $status = 'pending';
            if ($record) {
                $status = $record->status;
            }
            return [
                'session_id' => $session->id,
                'date' => $session->start_at->toIso8601String(),
                'status' => $status,
            ];
        });
        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }

    /**
     * 🎨 HÀM ĐĂNG KÝ KHUÔN MẶT (registerFace)
     * (Code hàm 'registerFace' của bạn đã ổn, giữ nguyên)
     */
    public function registerFace(Request $request)
    {
        try {
            $data = $request->validate([
                'template_base64' => 'required|string',
            ]);
            $user = auth('api')->user();
            $student = $user->student ?? null;
            if (!$student) {
                return response()->json(['error' => 'Student profile not found'], 400);
            }
            $base64String = $data['template_base64'];
            try {
                $id = DB::table('face_templates_simple')->insertGetId([
                    'student_id'    => $student->id,
                    'template'      => $base64String,
                    'created_at'    => Carbon::now(),
                ]);
            } catch (\Illuminate\Database\QueryException $e) {
                if (str_contains($e->getMessage(), 'Unknown column \'created_at\'')) {
                    $id = DB::table('face_templates_simple')->insertGetId([
                        'student_id'    => $student->id,
                        'template'      => $base64String,
                    ]);
                } else {
                    throw $e;
                }
            }
            $user->face_image_path = 'registered';
            $user->save();
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
}
