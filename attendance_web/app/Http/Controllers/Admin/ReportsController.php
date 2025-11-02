<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportsController extends Controller
{
    public function attendance(Request $r)
    {
        $base = DB::table('attendance_records as ar')
            ->join('attendance_sessions as s', 's.id', '=', 'ar.attendance_session_id')
            ->join('class_sections as cs', 'cs.id', '=', 's.class_section_id')
            ->join('courses as c', 'c.id', '=', 'cs.course_id')
            ->join('students as st', 'st.id', '=', 'ar.student_id')
            ->join('users as u', 'u.id', '=', 'st.user_id');

        if ($r->filled('date_from')) $base->whereDate('s.start_at', '>=', $r->date_from);
        if ($r->filled('date_to')) $base->whereDate('s.start_at', '<=', $r->date_to);
        if ($r->filled('course_id')) $base->where('c.id', $r->course_id);
        if ($r->filled('class_section_id')) $base->where('cs.id', $r->class_section_id);

        $total = (clone $base)->count();
        $present = (clone $base)->where('ar.status', 'present')->count();
        $late = (clone $base)->where('ar.status', 'late')->count();
        $absent = (clone $base)->where('ar.status', 'absent')->count();
        $rate = $total ? round($present * 100 / $total, 1) : 0;

        $rows = (clone $base)
            ->selectRaw('DATE(s.start_at) as date, st.student_code, u.name as student_name, c.code as course_code, c.name as course_name, cs.id as class_section_id, ar.status, ar.created_at')
            ->orderByDesc('date')
            ->paginate(20)->withQueryString();

        return view('admin.reports.attendance', compact('rows', 'rate', 'present', 'late', 'absent', 'total'));
    }

    public function exportCsv(Request $r)
    {
        $filename = 'attendance_' . now()->format('Ymd_His') . '.csv';
        return response()->streamDownload(function () use ($r) {
            $q = DB::table('attendance_records as ar')
                ->join('attendance_sessions as s', 's.id', '=', 'ar.attendance_session_id')
                ->join('class_sections as cs', 'cs.id', '=', 's.class_section_id')
                ->join('courses as c', 'c.id', '=', 'cs.course_id')
                ->join('students as st', 'st.id', '=', 'ar.student_id')
                ->join('users as u', 'u.id', '=', 'st.user_id')
                ->selectRaw('DATE(s.start_at) as date, st.student_code, u.name as student_name, c.code as course_code, c.name as course_name, cs.id as class_section_id, ar.status, ar.created_at');

            if ($r->filled('date_from')) $q->whereDate('s.start_at', '>=', $r->date_from);
            if ($r->filled('date_to')) $q->whereDate('s.start_at', '<=', $r->date_to);

            $out = fopen('php://output', 'w');
            fputcsv($out, ['date', 'student_code', 'student_name', 'course_code', 'course_name', 'class_section_id', 'status', 'created_at']);
            foreach ($q->cursor() as $row) {
                fputcsv($out, [(string)$row->date, $row->student_code, $row->student_name, $row->course_code, $row->course_name, $row->class_section_id, $row->status, (string)$row->created_at]);
            }
            fclose($out);
        }, $filename, ['Content-Type' => 'text/csv']);
    }
}
