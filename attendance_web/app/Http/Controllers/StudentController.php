<?php

namespace App\Http\Controllers;

use App\Models\{Student, ClassSection, Schedule, AttendanceSession, AttendanceRecord};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class StudentController extends Controller
{
    /**
     * 📅 Lấy lịch học chi tiết theo ngày cho sinh viên đã đăng nhập.
     * Hàm này đã được sửa lại để trả về đầy đủ thông tin buổi học.
     */
    public function schedule(Request $request)
    {
        // 1. Lấy ngày và thông tin sinh viên (giữ nguyên)
        $date = $request->input('date') ?? now()->toDateString();
        $user = auth('api')->user();
        $student = Student::where('user_id', $user->id)->firstOrFail();

        // 2. Chuyển đổi thứ (giữ nguyên)
        // Chuẩn Carbon: 0=CN, 1=T2, ..., 6=T7
        // Chuẩn của bạn: 0=T2, 1=T3, ..., 6=CN
        $carbonDate = Carbon::parse($date);
        $carbonWeekday = $carbonDate->dayOfWeek;
        $weekday = ($carbonWeekday === 0) ? 6 : $carbonWeekday - 1;

        // 3. Query thẳng vào VIEW 'vw_student_schedule' (PHẦN THAY THẾ)
        $schedules = DB::table('vw_student_schedule')
            ->where('student_id', $student->id)  // Lọc đúng sinh viên
            ->where('weekday', $weekday)         // Lọc đúng thứ trong tuần
            ->whereDate('start_date', '<=', $date) // Lọc ngày bắt đầu
            ->whereDate('end_date', '>=', $date)   // Lọc ngày kết thúc
            ->orderBy('start_time')              // Sắp xếp theo giờ bắt đầu
            ->get();

        // 4. Biến đổi dữ liệu (vẫn cần làm để ghép ngày + giờ)
        $formattedSchedules = $schedules->map(function ($schedule) use ($carbonDate) {

            // Ghép NGÀY đang chọn ($carbonDate) với GIỜ từ DB ($schedule->start_time)
            $dbTime = Carbon::parse($schedule->start_time);
            $startTime = $carbonDate->copy()->setTime(
                $dbTime->hour,
                $dbTime->minute,
                $dbTime->second
            );

            // Làm tương tự cho end_time
            $dbEndTime = Carbon::parse($schedule->end_time);
            $endTime = $carbonDate->copy()->setTime(
                $dbEndTime->hour,
                $dbEndTime->minute,
                $dbEndTime->second
            );

            return [
                // Đảm bảo view của bạn có cột 'class_section_id'
                'class_section_id' => $schedule->class_section_id,
                'course_code' => $schedule->course_code,
                'course_name' => $schedule->course_name,
                'class_name'  => $schedule->course_code, // Dùng 'term' từ view
                'room'        => $schedule->room,
                'start_time'  => $startTime->toIso8601String(), // "2025-10-22T08:00:00Z"
                'end_time'    => $endTime->toIso8601String(),   // "2025-10-22T10:00:00Z"

                // Các thông tin khác nếu Flutter cần
                // 'schedule_id' => $schedule->id, // (Nếu bạn có cột này trong view)
            ];
        });

        // 5. Trả về JSON (giữ nguyên)
        return response()->json([
            'success' => true,
            'data' => $formattedSchedules,
        ]);
    }


    /**
     * 📸 Xử lý việc check-in điểm danh của sinh viên.
     */
    public function checkIn(Request $r)
    {
        $data = $r->validate([
            'attendance_session_id' => 'required|exists:attendance_sessions,id',
            'status' => 'required|in:present,late,absent',
            'photo' => 'required|image|max:4096',
            'gps_lat' => 'nullable|numeric',
            'gps_lng' => 'nullable|numeric',
            'password' => 'nullable|string',
        ]);

        $user = auth('api')->user();
        $student = Student::where('user_id', $user->id)->firstOrFail();
        $session = AttendanceSession::findOrFail($data['attendance_session_id']);

        // Kiểm tra khung giờ
        if (now()->lt($session->start_at) || now()->gt($session->end_at)) {
            return response()->json(['error' => 'Session is not active'], 400);
        }

        // Check password nếu required
        $flags = $session->mode_flags ?? [];
        if (!empty($flags['password']) && $session->password_hash) {
            if (empty($data['password']) || !Hash::check($data['password'], $session->password_hash)) {
                return response()->json(['error' => 'Invalid password'], 400);
            }
        }

        // Upload ảnh
        $path = $r->file('photo')->store('public/attendances');
        $url = Storage::url($path);

        // Ghi record (unique theo session+student)
        $rec = AttendanceRecord::updateOrCreate(
            ['attendance_session_id' => $session->id, 'student_id' => $student->id],
            [
                'status' => $data['status'],
                'photo_path' => $url,
                'gps_lat' => $data['gps_lat'] ?? null,
                'gps_lng' => $data['gps_lng'] ?? null,
                'created_at' => now(),
            ]
        );

        return response()->json(['message' => 'Checked in', 'record' => $rec]);
    }

    public function attendanceHistory(Request $request, $classSectionId)
    {
        $user = auth('api')->user();
        $student = Student::where('user_id', $user->id)->firstOrFail();

        // Lấy tất cả các buổi điểm danh đã được tạo cho lớp này
        $sessions = AttendanceSession::where('class_section_id', $classSectionId)
            ->orderBy('start_at', 'asc') // Sắp xếp các buổi học theo thứ tự thời gian
            ->get();

        // Biến đổi dữ liệu để trả về cho Flutter
        $history = $sessions->map(function ($session) use ($student) {
            // Tìm bản ghi điểm danh của sinh viên trong buổi học này
            $record = $session->records()->where('student_id', $student->id)->first();

            $status = 'pending'; // Mặc định là 'pending'

            if ($record) {
                // Nếu có bản ghi, lấy trạng thái từ đó
                $status = $record->status;
            }

            // XÓA BỎ toàn bộ phần logic elseif.
            // Hãy để Flutter tự quyết định dựa trên ngày và trạng thái 'pending'.

            return [
                'session_id' => $session->id,
                'date' => $session->start_at->toIso8601String(),
                'status' => $status, // Sẽ là 'present', 'late', 'absent', hoặc 'pending'
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }
}
