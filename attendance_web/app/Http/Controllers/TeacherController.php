<?php


namespace App\Http\Controllers;


use App\Models\{Teacher,ClassSection,Schedule,AttendanceSession,AttendanceRecord};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Carbon;


class TeacherController extends Controller
{
    public function schedule(Request $r)
    {
        $date = $r->query('date');
        $user = auth('api')->user();
        $teacher = Teacher::where('user_id',$user->id)->firstOrFail();
// Lấy lịch theo ngày: one-off hoặc recurring theo weekday
        $weekday = Carbon::parse($date ?? now())->dayOfWeek; // 0=Sun..6=Sat
        return ClassSection::with(['course'])
            ->where('teacher_id',$teacher->id)
            ->whereHas('schedules', function($q) use($date,$weekday){
                $q->where(function($qq) use($date){ $qq->where('recurring_flag',0)->whereDate('date',$date); })
                    ->orWhere(function($qq) use($weekday){ $qq->where('recurring_flag',1)->where('weekday',$weekday); });
            })->get();
    }


    public function createSession(Request $r)
    {
        $data = $r->validate([
            'class_section_id' => 'required|exists:class_sections,id',
            'start_at' => 'required|date',
            'end_at' => 'required|date|after:start_at',
            'mode_flags' => 'required|array',
            'password' => 'nullable|string',
            'schedule_id' => 'nullable|exists:schedules,id',
        ]);
        $data['created_by'] = auth('api')->id();
        if (!empty($data['password'])) {
            $data['password_hash'] = Hash::make($data['password']);
            unset($data['password']);
        }
        $session = AttendanceSession::create($data);


// Nếu bật QR, tạo token hết hạn nhanh (15 phút)
        $qr = null;
        if (!empty($data['mode_flags']['qr'])) {
            $token = hash('sha256', Str::random(64));
            $session->qrTokens()->create([
                'token' => $token,
                'expires_at' => now()->addMinutes(15),
            ]);
            $qr = [
                'token' => $token,
                'deep_link' => url("/attendance/checkin?token={$token}"),
            ];
        }


        return response()->json(['session' => $session, 'qr' => $qr], 201);
    }


    public function sessionDetail($id)
    {
        return AttendanceSession::with(['classSection.course','records.student.user'])->findOrFail($id);
    }
}
