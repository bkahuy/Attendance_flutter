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
            'status'           => 'nullable|in:present,late,absent',
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
                'status'     => $data['status'] ?? 'open',
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
                'expires_at' => $data['end_at'],
            ]);

            // Nếu tạo QR tức là giảng viên muốn mở phiên ngay lập tức,
            // đặt trạng thái phiên thành 'active' để sinh viên có thể truy cập.
            try {
                $session->status = 'active';
                $session->save();
            } catch (\Throwable $e) {
                // Không để lỗi nhỏ phá hỏng flow tạo phiên; log để debug
                Log::warning('[teacher.createSession] failed to set session active: ' . $e->getMessage());
            }

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


    public function closeSession($id)
    {
        try {
            // Kiểm tra quyền giảng viên
            $teacherUserId = auth('api')->id();
            if (!$teacherUserId) {
                return response()->json(['error' => 'UNAUTHENTICATED'], 401);
            }

            // Lấy thông tin session và kiểm tra quyền
            $session = AttendanceSession::find($id);

            if (!$session) {
                return response()->json(['error' => 'SESSION_NOT_FOUND'], 404);
            }

            // Kiểm tra session này có thuộc về giảng viên đang đăng nhập không
            $checkPermission = DB::selectOne("
                SELECT cs.id
                FROM class_sections cs
                JOIN teachers t ON t.id = cs.teacher_id
                JOIN attendance_sessions ats ON ats.class_section_id = cs.id
                WHERE ats.id = ? AND t.user_id = ?
            ", [$id, $teacherUserId]);

            if (!$checkPermission) {
                return response()->json(['error' => 'NO_PERMISSION'], 403);
            }

            // Cập nhật status thành closed
            $session->end_at = now();
            $session->status = 'closed';
            $session->save();

            $session->qrTokens()->delete();

            // Lấy thống kê nhanh
            $stats = DB::selectOne("
                SELECT
                    COUNT(ar.id) as total_records,
                    SUM(CASE WHEN ar.status = 'present' THEN 1 ELSE 0 END) as present_count,
                    SUM(CASE WHEN ar.status = 'late' THEN 1 ELSE 0 END) as late_count
                FROM attendance_records ar
                WHERE ar.attendance_session_id = ?
            ", [$id]);

            return response()->json([
                'message' => 'Đã đóng phiên điểm danh thành công.',
                'session' => [
                    'id' => (int) $session->id,
                    'status' => $session->status,
                    'start_at' => $session->start_at,
                    'end_at' => $session->end_at,
                ],
                'stats' => [
                    'total_records' => (int) ($stats->total_records ?? 0),
                    'present_count' => (int) ($stats->present_count ?? 0),
                    'late_count' => (int) ($stats->late_count ?? 0),
                ]
            ]);

        } catch (\Throwable $e) {
            Log::error('[teacher.closeSession] ' . $e->getMessage(), [
                'session_id' => $id
            ]);
            return response()->json(['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
        }
    }


    public function showSessionDetail($id)
    {
        try {
            // 1. Lấy thông tin cơ bản của buổi học
            $sessionInfo = DB::table('attendance_sessions as a_sess')
                ->join('class_sections as cs', 'a_sess.class_section_id', '=', 'cs.id')
                ->join('courses as c', 'cs.course_id', '=', 'c.id')
                ->where('a_sess.id', $id)
                ->select(
                    'a_sess.id',
                    'a_sess.start_at',
                    'a_sess.end_at',
                    'a_sess.status as session_status',
                    'c.name as course_name',
                    'cs.id as class_section_id'
                )
                ->first();

            if (!$sessionInfo) {
                return response()->json(['message' => 'Không tìm thấy buổi học.'], 404);
            }

            // 2. Lấy danh sách sinh viên và trạng thái điểm danh
            // Dùng câu lệnh LEFT JOIN (từ câu trả lời đầu tiên của tôi)
            $students = DB::table('class_section_students as css')
                ->join('students as s', 'css.student_id', '=', 's.id')
                ->join('users as u', 's.user_id', '=', 'u.id')
                ->leftJoin('attendance_records as ar', function($join) use ($id) {
                    $join->on('ar.student_id', '=', 's.id')
                        ->where('ar.attendance_session_id', '=', $id); // Chỉ join với session ID này
                })
                ->where('css.class_section_id', $sessionInfo->class_section_id)
                ->select(
                    's.id as student_id',
                    'u.name as student_name',
                    's.student_code',
                    'ar.created_at as checkin_time',
                    DB::raw("COALESCE(ar.status, 'absent') as status")
                )
                ->orderBy('u.name')
                ->get();

            // 3. Đếm số lượng
            // (Chúng ta phải đếm từ collection $students vì nó đã bao gồm cả 'absent')
            $counts = $students->countBy('status');

            // 4. Trả về MỘT OBJECT (Map) duy nhất
            return response()->json([
                // 'data' là tùy chọn, nhưng nên có
                // để khớp với res.data['data'] trong Flutter
                'data' => [
                    'session_info' => $sessionInfo,
                    'students' => $students,
                    'present_count' => $counts->get('present', 0),
                    'late_count' => $counts->get('late', 0),
                    'absent_count' => $counts->get('absent', 0),
                ]
            ]);

        } catch (\Exception $e) {
            // Log::error('Lỗi khi lấy chi tiết buổi học: ' . $e->getMessage());
            return response()->json(['message' => 'Lỗi máy chủ: ' . $e->getMessage()], 500);
        }
    }


    public function sessionDetail($id)
    {
        try {
            $details = DB::table('class_section_students as css')
                ->where('css.class_section_id', $id)
                ->join('students as s', 'css.student_id', '=', 's.id')
                ->join('users as u', 's.user_id', '=', 'u.id')
                ->join('attendance_sessions as a_sess', 'a_sess.class_section_id', '=', 'css.class_section_id')
                ->leftJoin('attendance_records as ar', function ($join) {
                    $join->on('ar.student_id', '=', 's.id')
                        ->on('ar.attendance_session_id', '=', 'a_sess.id');
                })
                ->select(
                    'u.name as student_name',
                    's.student_code',
                    'a_sess.id as session_id',
                    'ar.created_at as checkin_time',
                    'ar.status as attendance_status',
                )
                ->orderBy('u.name', 'asc')
                ->get();

            if ($details->isEmpty()) {
                // Vẫn dùng response()->json() để trả về lỗi 404
                return response()->json([
                    'message' => 'Không tìm thấy dữ liệu.'
                ], 404);
            }

            // Vẫn dùng response()->json() để trả về dữ liệu
            return response()->json(['data' => $details], 200);

        } catch (\Exception $e) {
            // Log::error('Lỗi khi lấy chi tiết session: ' . $e->getMessage());

            // Vẫn dùng response()->json() để trả về lỗi 500
            return response()->json(['message' => 'Đã xảy ra lỗi máy chủ.'], 500);
        }
    }

    public function getSessionsByClassSection($classSectionId)
    {
        try {
            // Kiểm tra quyền: giảng viên chỉ được xem phiên của lớp mình dạy
            $teacherUserId = auth('api')->id();
            if (!$teacherUserId) {
                return response()->json(['error' => 'UNAUTHENTICATED'], 401);
            }

            // Kiểm tra class_section có thuộc giảng viên này không
            $checkPermission = DB::selectOne("
                SELECT cs.id
                FROM class_sections cs
                JOIN teachers t ON t.id = cs.teacher_id
                WHERE cs.id = ? AND t.user_id = ?
            ", [$classSectionId, $teacherUserId]);

            if (!$checkPermission) {
                return response()->json(['error' => 'CLASS_SECTION_NOT_FOUND_OR_NO_PERMISSION'], 403);
            }

            // Lấy danh sách các phiên điểm danh với thống kê
            $sessions = DB::select("
                SELECT
                    ats.id,
                    ats.start_at,
                    ats.end_at,
                    ats.mode_flags,
                    ats.created_at,
                    COUNT(ar.id) as total_records,
                    SUM(CASE WHEN ar.status = 'present' THEN 1 ELSE 0 END) as present_count,
                    CASE
                        WHEN NOW() BETWEEN ats.start_at AND ats.end_at THEN 'active'
                        WHEN NOW() > ats.end_at THEN 'ended'
                        ELSE 'upcoming'
                    END as status
                FROM attendance_sessions ats
                LEFT JOIN attendance_records ar ON ar.attendance_session_id = ats.id
                WHERE ats.class_section_id = ?
                GROUP BY ats.id, ats.start_at, ats.end_at, ats.mode_flags, ats.created_at
                ORDER BY ats.created_at DESC
            ", [$classSectionId]);

            // Chuyển đổi mode_flags từ JSON string sang array
            $sessions = array_map(function ($session) {
                return [
                    'id' => (int) $session->id,
                    'start_at' => $session->start_at,
                    'end_at' => $session->end_at,
                    'mode_flags' => json_decode($session->mode_flags, true),
                    'created_at' => $session->created_at,
                    'total_records' => (int) $session->total_records,
                    'present_count' => (int) $session->present_count,
                    'status' => $session->status,
                ];
            }, $sessions);

            return response()->json([
                'class_section_id' => (int) $classSectionId,
                'sessions' => $sessions,
            ]);

        } catch (\Throwable $e) {
            Log::error('[teacher.getSessionsByClassSection] ' . $e->getMessage(), [
                'class_section_id' => $classSectionId
            ]);
            return response()->json(['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
        }
    }

    public function getAttendanceRecords($sessionId)
    {
        try {
            // Kiểm tra quyền: giảng viên chỉ được xem phiên của lớp mình dạy
            $teacherUserId = auth('api')->id();
            if (!$teacherUserId) {
                return response()->json(['error' => 'UNAUTHENTICATED'], 401);
            }

            // Kiểm tra quyền truy cập session
            $sessionInfo = DB::selectOne("
                SELECT
                    ats.id,
                    ats.class_section_id,
                    ats.start_at,
                    ats.end_at,
                    cs.teacher_id,
                    t.user_id as teacher_user_id
                FROM attendance_sessions ats
                JOIN class_sections cs ON cs.id = ats.class_section_id
                JOIN teachers t ON t.id = cs.teacher_id
                WHERE ats.id = ?
            ", [$sessionId]);

            if (!$sessionInfo) {
                return response()->json(['error' => 'SESSION_NOT_FOUND'], 404);
            }

            if ($sessionInfo->teacher_user_id != $teacherUserId) {
                return response()->json(['error' => 'NO_PERMISSION'], 403);
            }

            // Lấy danh sách sinh viên đã điểm danh
            $attendanceRecords = DB::select("
                SELECT
                    ar.id,
                    ar.student_id,
                    s.student_code,
                    u.name as student_name,
                    u.email,
                    ar.status,
                    ar.checked_in_at,
                    ar.note,
                    ar.check_in_method
                FROM attendance_records ar
                JOIN students s ON s.id = ar.student_id
                JOIN users u ON u.id = s.user_id
                WHERE ar.attendance_session_id = ?
                ORDER BY ar.checked_in_at DESC
            ", [$sessionId]);

            // Lấy danh sách tất cả sinh viên trong lớp
            $allStudents = DB::select("
                SELECT
                    s.id as student_id,
                    s.student_code,
                    u.name as student_name,
                    u.email
                FROM class_section_students css
                JOIN students s ON s.id = css.student_id
                JOIN users u ON u.id = s.user_id
                WHERE css.class_section_id = ?
            ", [$sessionInfo->class_section_id]);

            // Lấy danh sách student_id đã điểm danh
            $attendedStudentIds = array_map(function($record) {
                return $record->student_id;
            }, $attendanceRecords);

            // Sinh viên chưa điểm danh
            $absentStudents = array_filter($allStudents, function($student) use ($attendedStudentIds) {
                return !in_array($student->student_id, $attendedStudentIds);
            });

            $absentStudents = array_map(function($student) {
                return [
                    'student_id' => (int) $student->student_id,
                    'student_code' => $student->student_code,
                    'student_name' => $student->student_name,
                    'email' => $student->email,
                    'status' => 'absent',
                ];
            }, array_values($absentStudents));

            // Format attendance records
            $attendanceRecords = array_map(function($record) {
                return [
                    'id' => (int) $record->id,
                    'student_id' => (int) $record->student_id,
                    'student_code' => $record->student_code,
                    'student_name' => $record->student_name,
                    'email' => $record->email,
                    'status' => $record->status,
                    'checked_in_at' => $record->checked_in_at,
                    'note' => $record->note,
                    'check_in_method' => $record->check_in_method ?? 'unknown',
                ];
            }, $attendanceRecords);

            // Đếm theo status
            $presentCount = count(array_filter($attendanceRecords, fn($r) => $r['status'] === 'present'));
            $lateCount = count(array_filter($attendanceRecords, fn($r) => $r['status'] === 'late'));

            return response()->json([
                'session_id' => (int) $sessionId,
                'session_info' => [
                    'start_at' => $sessionInfo->start_at,
                    'end_at' => $sessionInfo->end_at,
                    'is_active' => now()->between($sessionInfo->start_at, $sessionInfo->end_at),
                ],
                'total_students' => count($allStudents),
                'present_count' => $presentCount,
                'late_count' => $lateCount,
                'absent_count' => count($absentStudents),
                'attendance_records' => $attendanceRecords,
                'absent_students' => $absentStudents,
            ]);

        } catch (\Throwable $e) {
            Log::error('[teacher.getAttendanceRecords] ' . $e->getMessage(), [
                'session_id' => $sessionId
            ]);
            return response()->json(['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
        }
    }


    public function searchAttendanceHistory(Request $request)
    {
        try {
            // Kiểm tra quyền giảng viên
            $teacherUserId = auth('api')->id();
            if (!$teacherUserId) {
                return response()->json(['error' => 'UNAUTHENTICATED'], 401);
            }

            // Lấy các tham số tìm kiếm
            $courseName = $request->query('course_name');
            $className = $request->query('class_names');
            $room = $request->query('room');
            $startTime = $request->query('start_time');
            $endTime = $request->query('end_time');
//            $time = $request->query('time');

            // Xây dựng câu query với các điều kiện WHERE động
            $params = [$teacherUserId];
            $whereConditions = ["t.user_id = ?"];

            if ($courseName) {
                $whereConditions[] = "(c.name LIKE ?)";
                $params[] = "%{$courseName}%";

            }

            if ($className) {
                $whereConditions[] = "(cl.name LIKE ?)";
                $params[] = "%{$className}%";
            }

            if ($room) {
                $whereConditions[] = "cs.room LIKE ?";
                $params[] = "%{$room}%";
            }

//            if ($time) {
//                $whereConditions[] = "(TIME(ats.start_at) LIKE ?)";
//                $params[] = "{$time}%";
//            }

            if ($startTime) {
                $whereConditions[] = "(s.start_time LIKE ?)";
                $params[] = "%{$startTime}%";
            }


            $whereClause = implode(' AND ', $whereConditions);

            // Query chính để lấy danh sách phiên điểm danh
            $sql = "
                SELECT DISTINCT
                    ats.id as session_id,
                    ats.start_at,
                    ats.end_at,
                    ats.created_at,
                    s.start_time,
                    cs.id as class_section_id,
                    cs.term,
                    cs.room,
                    c.code as course_code,
                    c.name as course_name,
                    GROUP_CONCAT(DISTINCT cl.name SEPARATOR ', ') as class_names,
                    CASE
                        WHEN NOW() BETWEEN ats.start_at AND ats.end_at THEN 'active'
                        WHEN NOW() > ats.end_at THEN 'ended'
                        ELSE 'upcoming'
                    END as status
                FROM attendance_sessions ats
                JOIN class_sections cs ON cs.id = ats.class_section_id
                JOIN courses c ON c.id = cs.course_id
                JOIN teachers t ON t.id = cs.teacher_id
                JOIN schedules s ON s.class_section_id = ats.class_section_id
                LEFT JOIN class_section_classes csc ON csc.class_section_id = cs.id
                LEFT JOIN classes cl ON cl.id = csc.class_id
                WHERE {$whereClause}
                GROUP BY ats.id, ats.start_at, ats.end_at, ats.created_at,
                         cs.id, cs.term, cs.room, c.code, c.name, s.start_time
                ORDER BY ats.created_at DESC
            ";

            $results = DB::select($sql, $params);

            // Lọc theo class_name nếu có (vì GROUP_CONCAT không thể dùng trong WHERE)
            if ($className) {
                $results = array_filter($results, function($session) use ($className) {
                    return stripos($session->class_names, $className) !== false;
                });
                $results = array_values($results);
            }

            // Lấy thống kê cho mỗi session
            $results = array_map(function ($session) {
                // Đếm số lượng điểm danh
                $stats = DB::selectOne("
                    SELECT
                        COUNT(ar.id) as total_records,
                        SUM(CASE WHEN ar.status = 'present' THEN 1 ELSE 0 END) as present_count,
                        SUM(CASE WHEN ar.status = 'late' THEN 1 ELSE 0 END) as late_count
                    FROM attendance_records ar
                    WHERE ar.attendance_session_id = ?
                ", [$session->session_id]);

                // Tổng số sinh viên trong lớp
                $totalStudents = DB::selectOne("
                    SELECT COUNT(*) as total
                    FROM class_section_students
                    WHERE class_section_id = ?
                ", [$session->class_section_id]);

                $totalStudentsCount = (int) $totalStudents->total;
                $presentCount = (int) ($stats->present_count ?? 0);
                $lateCount = (int) ($stats->late_count ?? 0);
                $totalRecords = (int) ($stats->total_records ?? 0);

                return [
                    'session_id' => (int) $session->session_id,
                    'class_section_id' => (int) $session->class_section_id,
                    'course_code' => $session->course_code,
                    'course_name' => $session->course_name,
                    'class_names' => $session->class_names ?? '',
                    'term' => $session->term ?? '',
                    'room' => $session->room ?? '',
                    'start_time' => $session->start_time,
                    'start_at' => $session->start_at,
                    'end_at' => $session->end_at,
                    'created_at' => $session->created_at,
                    'status' => $session->status,
                    'total_students' => $totalStudentsCount,
                    'total_records' => $totalRecords,
                    'present_count' => $presentCount,
                    'late_count' => $lateCount,
                    'absent_count' => $totalStudentsCount - $totalRecords,
                    'attendance_rate' => $totalStudentsCount > 0
                        ? round(($presentCount / $totalStudentsCount) * 100, 2)
                        : 0,
                ];
            }, $results);

            return response()->json([
                'total' => count($results),
                'results' => $results,
                'filters' => [
                    'course_name' => $courseName,
                    'class_name' => $className,
                    'room' => $room,
                    'start_time' => $startTime,
//                    'time' => $time,
                ],
            ]);

        } catch (\Throwable $e) {
            Log::error('[teacher.searchAttendanceHistory] ' . $e->getMessage(), [
                'request' => $request->all()
            ]);
            return response()->json(['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
        }
    }

    public function getActiveSessionByClass(Request $request, $classSectionId)
    {
        try {
            // 1. Kiểm tra quyền (Giữ nguyên logic của bạn)
            $teacherUserId = auth('api')->id();
            $checkPermission = DB::selectOne("
            SELECT cs.id
            FROM class_sections cs
            JOIN teachers t ON t.id = cs.teacher_id
            WHERE cs.id = ? AND t.user_id = ?
        ", [$classSectionId, $teacherUserId]);

            if (!$checkPermission) {
                return response()->json(['error' => 'NO_PERMISSION'], 403);
            }
            // 2. Tìm phiên ĐANG HOẠT ĐỘNG (dùng Eloquent cho ngắn gọn)
            $session = AttendanceSession::where('class_section_id', $classSectionId)
                ->whereRaw('NOW() BETWEEN start_at AND end_at')
                ->first();
            $qr = null;
            // 3. Nếu không tìm thấy, trả về 404 (Not Found)
            if (!$session) {
                return response()->json(['message' => 'No active session found'], 404);
            }
            else if ($session->status === 'open') {
                $qr = DB::table('qr_tokens')
                    ->where('attendance_session_id', $session->id)
                    ->select('token') // Chỉ chọn 2 cột app cần
                    ->first();
            }
            // 5. Trả về cấu trúc mà app Flutter mong đợi
            return response()->json([
                'session' => $session, // Tự động convert 'mode_flags' nếu bạn có $casts
                'qr'      => $qr      // Sẽ là null nếu không có QR, app Flutter đã xử lý
            ]);

        } catch (\Throwable $e) {
            Log::error('[teacher.getActiveSessionByClass] ' . $e->getMessage(), [
                'class_section_id' => $classSectionId
            ]);
            return response()->json(['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
        }
    }
}
