<?php


namespace App\Http\Controllers;


use App\Models\{Student,ClassSection,Schedule,AttendanceSession,AttendanceRecord};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;



class StudentController extends Controller
{
    public function schedule(Request $r)
    {
        $date = $r->query('date');
        $user = auth('api')->user();
        $student = Student::where('user_id',$user->id)->firstOrFail();
        $weekday = Carbon::parse($date ?? now())->dayOfWeek;


        return $student->classes()->with(['course'])
            ->whereHas('schedules', function($q) use($date,$weekday){
                $q->where(function($qq) use($date){ $qq->where('recurring_flag',0)->whereDate('date',$date); })
                    ->orWhere(function($qq) use($weekday){ $qq->where('recurring_flag',1)->where('weekday',$weekday); });
            })->get();
    }


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
        $student = Student::where('user_id',$user->id)->firstOrFail();
        $session = AttendanceSession::findOrFail($data['attendance_session_id']);


// Kiểm tra khung giờ
        if (now()->lt($session->start_at) || now()->gt($session->end_at)) {
            return response()->json(['error' => 'Session is not active'], 400);
        }


// Check password nếu required
        $flags = $session->mode_flags ?? [];
        if (!empty($flags['password']) && $session->password_hash) {
            if (empty($data['password']) || !\Illuminate\Support\Facades\Hash::check($data['password'], $session->password_hash)) {
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
    // 📅 Lấy lịch học theo ngày
    public function scheduleByDate(Request $request)
    {
        $date = $request->input('date') ?? now()->toDateString();
        $user = auth('api')->user();

        $student = Student::where('user_id', $user->id)->firstOrFail();
        $weekday = Carbon::parse($date)->dayOfWeek; // 0=CN, 1=T2...

        $classes = $student->classes()
            ->with(['course', 'schedules' => function ($q) use ($date, $weekday) {
                $q->where(function ($qq) use ($date) {
                    $qq->where('recurring_flag', 0)->whereDate('date', $date);
                })->orWhere(function ($qq) use ($weekday) {
                    $qq->where('recurring_flag', 1)->where('weekday', $weekday);
                });
            }])
            ->get();

        $schedules = $classes->flatMap(function ($class) {
            return $class->schedules->map(function ($schedule) use ($class) {
                return [
                    'course_name' => $class->course->name ?? '',
                    'class_name'  => $class->name,
                    'room'        => $schedule->room,
                    'start_time'  => $schedule->start_time,
                    'end_time'    => $schedule->end_time,
                ];
            });
        });

        return response()->json([
            'success' => true,
            'data' => $schedules->values(),
        ]);
    }

    // ✅ Check-in (giữ nguyên logic bạn có)
//    public function checkIn(Request $r)
//    {
//        $data = $r->validate([
//            'attendance_session_id' => 'required|exists:attendance_sessions,id',
//            'status' => 'required|in:present,late,absent',
//            'photo' => 'required|image|max:4096',
//            'gps_lat' => 'nullable|numeric',
//            'gps_lng' => 'nullable|numeric',
//            'password' => 'nullable|string',
//        ]);
//
//        $user = auth('api')->user();
//        $student = Student::where('user_id', $user->id)->firstOrFail();
//        $session = AttendanceSession::findOrFail($data['attendance_session_id']);
//
//        if (now()->lt($session->start_at) || now()->gt($session->end_at)) {
//            return response()->json(['error' => 'Session is not active'], 400);
//        }
//
//        $flags = $session->mode_flags ?? [];
//        if (!empty($flags['password']) && $session->password_hash) {
//            if (empty($data['password']) || !Hash::check($data['password'], $session->password_hash)) {
//                return response()->json(['error' => 'Invalid password'], 400);
//            }
//        }
//
//        $path = $r->file('photo')->store('public/attendances');
//        $url = Storage::url($path);
//
//        $rec = AttendanceRecord::updateOrCreate(
//            ['attendance_session_id' => $session->id, 'student_id' => $student->id],
//            [
//                'status' => $data['status'],
//                'photo_path' => $url,
//                'gps_lat' => $data['gps_lat'] ?? null,
//                'gps_lng' => $data['gps_lng'] ?? null,
//                'created_at' => now(),
//            ]
//        );
//
//        return response()->json(['message' => 'Checked in', 'record' => $rec]);
//    }
}
