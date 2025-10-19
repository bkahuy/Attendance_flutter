<?php

namespace App\Http\Controllers;

use App\Models\{Student, ClassSection, Schedule, AttendanceSession, AttendanceRecord};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;

class StudentController extends Controller
{
    /**
     * 📅 Lấy lịch học chi tiết theo ngày cho sinh viên đã đăng nhập.
     * Hàm này đã được sửa lại để trả về đầy đủ thông tin buổi học.
     */
    public function schedule(Request $request)
    {
        // Lấy ngày từ request, nếu không có thì dùng ngày hôm nay
        $date = $request->input('date') ?? now()->toDateString();
        $user = auth('api')->user();

        // Tìm thông tin sinh viên từ user_id
        $student = Student::where('user_id', $user->id)->firstOrFail();

        // Chuyển đổi thứ trong tuần từ chuẩn Carbon (0=CN) sang chuẩn của bạn (0=T2)
        $carbonWeekday = Carbon::parse($date)->dayOfWeek;
        $weekday = ($carbonWeekday === 0) ? 6 : $carbonWeekday - 1;

        // Lấy danh sách các lớp học của sinh viên
        $classes = $student->classes()
            ->with([
                'course', // Lấy thông tin môn học
                'schedules' => function ($query) use ($date, $weekday) {
                    // Chỉ lấy các lịch học (schedules) khớp với ngày đang chọn
                    $query->where(function ($q) use ($date) { // Lịch cố định (không lặp lại)
                        $q->where('recurring_flag', 0)->whereDate('date', $date);
                    })->orWhere(function ($q) use ($weekday) { // Lịch lặp lại theo thứ
                        $q->where('recurring_flag', 1)->where('weekday', $weekday);
                    });
                }
            ])
            ->whereHas('schedules', function ($query) use ($date, $weekday) {
                // Lọc để chỉ giữ lại những lớp (classes) có lịch học trong ngày hôm đó
                $query->where(function ($q) use ($date) {
                    $q->where('recurring_flag', 0)->whereDate('date', $date);
                })->orWhere(function ($q) use ($weekday) {
                    $q->where('recurring_flag', 1)->where('weekday', $weekday);
                });
            })
            ->get();

        // Biến đổi dữ liệu để tạo ra một danh sách lịch học phẳng, đúng cấu trúc
        $schedules = $classes->flatMap(function ($class) {
            // Bỏ qua nếu lớp không có lịch học nào (đã được lọc bởi whereHas)
            if (is_null($class->schedules)) {
                return [];
            }

            // Với mỗi lịch học, tạo một object mới chứa thông tin cần thiết
            return $class->schedules->map(function ($schedule) use ($class) {
                return [
                    'class_section_id' => $class->id,
                    'course_code' => $class->course->course_code ?? '',
                    'course_name' => $class->course->name ?? 'N/A',
                    'class_name'  => $class->name,
                    'room'        => $schedule->room, // ✅ Dữ liệu phòng học đây rồi!
                    'start_time'  => Carbon::parse($schedule->start_time)->format('Y-m-d H:i:s'),
                    'end_time'    => Carbon::parse($schedule->end_time)->format('Y-m-d H:i:s'),
                    // Bạn có thể thêm các trường dữ liệu khác của schedule ở đây nếu cần
                    'schedule_id' => $schedule->id,
                ];
            });
        });

        // Trả về JSON theo cấu trúc mà Flutter mong đợi
        return response()->json([
            'success' => true,
            'data' => $schedules->values(),
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

        // Lấy tất cả các buổi điểm danh của lớp học phần này
        $sessions = AttendanceSession::where('class_section_id', $classSectionId)
            ->orderBy('start_at', 'asc') // Sắp xếp các buổi học theo thứ tự
            ->get();

        // Biến đổi dữ liệu để trả về cho client
        $history = $sessions->map(function ($session) use ($student) {
            // Tìm bản ghi điểm danh tương ứng của sinh viên
            $record = AttendanceRecord::where('attendance_session_id', $session->id)
                ->where('student_id', $student->id)
                ->first();

            $status = 'pending'; // Trạng thái mặc định

            if ($record) {
                // Nếu có bản ghi, lấy trạng thái từ đó (present, late, absent)
                $status = $record->status;
            } elseif (now()->gt($session->end_at)) {
                // Nếu không có bản ghi và buổi học đã kết thúc -> vắng
                $status = 'absent';
            } elseif (now()->between($session->start_at, $session->end_at)) {
                // Nếu đang trong giờ học mà chưa điểm danh -> có thể điểm danh
                $status = 'can_attend';
            }

            return [
                'session_id' => $session->id,
                'date' => $session->start_at->toIso8601String(), // Trả về ngày giờ chuẩn
                'status' => $status,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }
}
