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
    public function schedule(Request $req)
    {
        $date = $req->query('date', now()->toDateString()); // YYYY-MM-DD

        // Lấy user id từ JWT guard 'api'. Nếu dev chưa có JWT, cho phép ?teacher_user_id=
        $teacherUserId = auth('api')->id() ?? (int) $req->query('teacher_user_id', 0);
        if (!$teacherUserId) {
            return response()->json(['error' => 'NO_TEACHER_USER_ID'], 422);
        }
//khong duong sua
        try {
            // Query thẳng (tương đương SP sp_teacher_daily_schedule) với thông tin lớp
            $rows = DB::select("
                SELECT sc.id AS class_section_id,
                       c.code AS course_code,
                       c.name AS course_name,
                       sc.term,
                       sc.room,
                       sch.start_time,
                       sch.end_time,
                       GROUP_CONCAT(cl.name SEPARATOR ', ') AS class_names
                FROM class_sections sc
                JOIN teachers t     ON t.id = sc.teacher_id
                JOIN users tu       ON tu.id = t.user_id
                JOIN courses c      ON c.id = sc.course_id
                JOIN schedules sch  ON sch.class_section_id = sc.id
                LEFT JOIN class_section_classes csc ON csc.class_section_id = sc.id
                LEFT JOIN classes cl ON cl.id = csc.class_id
                WHERE tu.id = ?
                  AND (
                    (sch.recurring_flag = 0 AND sch.date = ?)
                    OR
                    (sch.recurring_flag = 1 AND sch.weekday = WEEKDAY(?))
                  )
                GROUP BY sc.id, c.code, c.name, sc.term, sc.room, sch.start_time, sch.end_time
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
                    'class_names'      => (string) ($r->class_names ?? ''), // Tên các lớp
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

        // Xác thực người tạo (giảng viên)
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

        // ===== PHẦN THÊM MỚI: kiểm tra nếu có phiên trước đó trong cùng lớp học phần hôm nay =====
        $today = now()->toDateString();

        $existingSession = AttendanceSession::where('class_section_id', $data['class_section_id'])
            ->whereDate('created_at', $today)
            ->first();

        if ($existingSession) {
            // Nếu có thì cập nhật thay vì tạo mới
            $existingSession->update([
                'class_section_id' => $data['class_section_id'],
                'start_at'   => $data['start_at'],
                'end_at'     => $data['end_at'],
                'mode_flags' => $data['mode_flags'],
                'password_hash' => $data['password_hash'] ?? null,
                'schedule_id' => $data['schedule_id'] ?? null,
                'updated_at' => now(),
            ]);

            $session = $existingSession;
            $isNew = false;
        } else {
            // Nếu chưa có thì tạo mới
            $session = AttendanceSession::create($data);
            $isNew = true;
        }

        // ===== Tạo hoặc cập nhật mã QR =====
        $qr = null;
        $mode = $data['mode_flags'] ?? [];

        if (!empty($mode['qr'])) {
            // Tạo token QR mới
            $token = hash('sha256', Str::random(64));

            // Nếu đã có phiên -> xóa token cũ (nếu có)
            if (!$isNew) {
                $session->qrTokens()->delete();
            }

            $session->qrTokens()->create([
                'token'      => $token,
                'expires_at' => now()->addMinutes(15),
            ]);

            $qr = [
                'token'     => $token,
                'deep_link' => url("/api/attendance/resolve-qr?token={$token}"),
            ];
        }

        return response()->json([
            'message' => $isNew ? 'Tạo phiên điểm danh thành công.' : 'Đã cập nhật phiên điểm danh thành công.',
            'session' => $session,
            'qr' => $qr,
        ], $isNew ? 201 : 200);
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
