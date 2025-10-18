<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\{
    Teacher,
    ClassSection,
    AttendanceSession,
    AttendanceRecord
};

class TeacherController extends Controller
{
    /**
     * GET /api/teacher/schedule?date=YYYY-MM-DD
     * (DEV) có thể truyền teacher_user_id nếu chưa login JWT
     * Trả về: [
     *   { class_section_id, course_code, course_name, term, room, start_time, end_time }
     * ]
     */
    public function scheduleByDate(Request $req)
    {
        $date = $req->query('date', now()->toDateString()); // YYYY-MM-DD

        // Lấy user id từ JWT guard 'api'. Nếu dev chưa có JWT, cho phép ?teacher_user_id=
        $teacherUserId = auth('api')->id() ?? (int) $req->query('teacher_user_id', 0);
        if (!$teacherUserId) {
            return response()->json(['error' => 'NO_TEACHER_USER_ID'], 422);
        }

        try {
            // Query thẳng (tương đương SP sp_teacher_daily_schedule)
            $rows = DB::select("
                SELECT sc.id AS class_section_id,
                       c.code AS course_code,
                       c.name AS course_name,
                       sc.term,
                       sc.room,
                       sch.start_time,
                       sch.end_time
                FROM class_sections sc
                JOIN teachers t     ON t.id = sc.teacher_id
                JOIN users tu       ON tu.id = t.user_id
                JOIN courses c      ON c.id = sc.course_id
                JOIN schedules sch  ON sch.class_section_id = sc.id
                WHERE tu.id = ?
                  AND (
                    (sch.recurring_flag = 0 AND sch.date = ?)
                    OR
                    (sch.recurring_flag = 1 AND sch.weekday = WEEKDAY(?))
                  )
                ORDER BY sch.start_time
            ", [$teacherUserId, $date, $date]);

            // Map ra đúng key Flutter đang đọc
            $data = array_map(function ($r) {
                return [
                    'class_section_id' => (int) $r->class_section_id,
                    'course_code'      => (string) $r->course_code,
                    'course_name'      => (string) $r->course_name,
                    'term'             => (string) ($r->term ?? ''),
                    'room'             => (string) ($r->room ?? ''),
                    'start_time'       => (string) $r->start_time, // HH:MM:SS
                    'end_time'         => (string) $r->end_time,   // HH:MM:SS
                    // 'period'        => 'T 2–3', // nếu muốn server đẩy luôn
                    // 'status'        => 'next',
                    // 'groups'        => 'K66-CNTT1',
                ];
            }, $rows);

            return response()->json($data);
        } catch (\Throwable $e) {
            Log::error('[teacher.schedule] ' . $e->getMessage(), ['date' => $date, 'uid' => $teacherUserId]);
            return response()->json(['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
        }
    }

    /**
     * POST /api/attendance/session
     * body: class_section_id, start_at, end_at, mode_flags{camera?,gps?,password?}, password?
     * optional: schedule_id
     */
    public function createSession(Request $r)
    {
        $data = $r->validate([
            'class_section_id' => 'required|exists:class_sections,id',
            'start_at'         => 'required|date',
            'end_at'           => 'required|date|after:start_at',
            'mode_flags'       => 'required|array',
            'password'         => 'nullable|string',
            'schedule_id'      => 'nullable|exists:schedules,id',
        ]);

        // Bắt buộc đăng nhập JWT để biết ai tạo
        $creatorId = auth('api')->id();
        if (!$creatorId) {
            return response()->json(['error' => 'UNAUTHENTICATED'], 401);
        }
        $data['created_by'] = $creatorId;

        // Nếu có password -> hash vào password_hash
        if (!empty($data['password'])) {
            $data['password_hash'] = Hash::make($data['password']);
            unset($data['password']);
        }

        // Lưu JSON đúng kiểu
        // Bảo đảm model AttendanceSession có $casts = ['mode_flags' => 'array'];
        $session = AttendanceSession::create($data);

        // Nếu bật QR trong mode_flags -> tạo token 15 phút
        $qr = null;
        $mode = $data['mode_flags'] ?? [];
        if (!empty($mode['qr'])) {
            $token = hash('sha256', Str::random(64));
            $session->qrTokens()->create([
                'token'      => $token,
                'expires_at' => now()->addMinutes(15),
            ]);

            // NOTE: sửa deep_link này KHỚP với route student dùng để resolve
            $qr = [
                'token'     => $token,
                // Nếu app Flutter đang gọi /api/attendance/resolve-qr
                'deep_link' => url("/api/attendance/resolve-qr?token={$token}"),
            ];
        }

        return response()->json(['session' => $session, 'qr' => $qr], 201);
    }

    /**
     * GET /api/attendance/session/{id}
     */
    public function sessionDetail($id)
    {
        return AttendanceSession::with(['classSection.course', 'records.student.user'])
            ->findOrFail($id);
    }
}
