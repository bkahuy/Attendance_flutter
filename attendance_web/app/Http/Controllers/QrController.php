<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\AttendanceSession;

class QrController extends Controller
{
    public function resolve(Request $request)
    {
        // ✅ Validate đầu vào
        $request->validate([
            'token' => 'required|string'
        ]);

        $now = now();

        // ✅ Tìm QR token hợp lệ
        $qr = DB::table('qr_tokens')
            ->where('token', $request->token)
            ->where('expires_at', '>', $now)
            ->first();

        if (!$qr) {
            return response()->json(['error' => 'Mã QR không hợp lệ hoặc đã hết hạn.'], 400);
        }

        // ✅ Lấy thông tin phiên điểm danh
        $session = AttendanceSession::with('classSection.course', 'classSection.classes')->find($qr->attendance_session_id);

        if (!$session) {
            return response()->json(['error' => 'Phiên điểm danh không tồn tại.'], 404);
        }

        $now = now();
        $sessionStart = $session->start_at ? \Carbon\Carbon::parse($session->start_at) : null;
        $sessionEnd = $session->end_at ? \Carbon\Carbon::parse($session->end_at) : null;

        $inTimeWindow = false;
        if ($sessionStart && $sessionEnd) {
            $inTimeWindow = $now->between($sessionStart, $sessionEnd);
        }

        if (!in_array($session->status, ['open','closed','cancelled']) && !$inTimeWindow) {
            // Trả thêm thông tin để debug (status + thời gian phiên)
            return response()->json([
                'error' => 'Phiên điểm danh đã kết thúc hoặc chưa mở.',
                'session_status' => $session->status,
                'start_at' => $sessionStart?->toDateTimeString(),
                'end_at' => $sessionEnd?->toDateTimeString(),
            ], 400);
        }

        // ✅ Trả dữ liệu chi tiết để app sinh viên xử lý check-in
        return response()->json([
            'session_id' => $session->id,
            'class_section' => [
                'id'     => $session->class_section_id,
                'course' => $session->classSection?->course?->name,
                'class_name' => $session->classSection?->classes?->first()?->name,
                'term'   => $session->classSection?->term,
                'room'   => $session->classSection?->room,
            ],
            'start_at'          => $session->start_at,
            'end_at'            => $session->end_at,
            'mode_flags'        => $session->mode_flags,
            'requires_password' => !empty($session->password_hash),
        ], 200);
    }
}
