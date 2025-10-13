<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Controller;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $today = Carbon::today();
        $weekday = $today->dayOfWeekIso; // 1..7

        // 1) Số SV đã điểm danh hôm nay (present/late)
        $studentsCheckedToday = DB::table('attendance_records as r')
            ->join('attendance_sessions as s', 's.id', '=', 'r.attendance_session_id')
            ->whereDate('s.start_at', $today)
            ->whereIn('r.status', ['present', 'late'])
            ->count();

        // 2) Số lớp có lịch học trong ngày hôm nay
        $classesTodayRecurring = DB::table('schedules')
            ->where('recurring_flag', 1)
            ->where('weekday', $weekday)
            ->distinct('class_section_id')
            ->count('class_section_id');

        $classesTodayOneoff = DB::table('schedules')
            ->where('recurring_flag', 0)
            ->whereDate('date', $today)
            ->distinct('class_section_id')
            ->count('class_section_id');

        $classesToday = $classesTodayRecurring + $classesTodayOneoff;

        // 3) Tỉ lệ có mặt (present+late)/total trong HÔM NAY
        $totalToday = DB::table('attendance_records as r')
            ->join('attendance_sessions as s', 's.id', '=', 'r.attendance_session_id')
            ->whereDate('s.start_at', $today)
            ->count();

        $presentLateToday = DB::table('attendance_records as r')
            ->join('attendance_sessions as s', 's.id', '=', 'r.attendance_session_id')
            ->whereDate('s.start_at', $today)
            ->whereIn('r.status', ['present','late'])
            ->count();

        $attendanceRate = $totalToday > 0 ? round(($presentLateToday / $totalToday) * 100) : 0;

        // 4) Top 3 lớp có lượt điểm danh cao nhất hôm nay
        $topClasses = DB::table('attendance_records as r')
            ->join('attendance_sessions as s','s.id','=','r.attendance_session_id')
            ->join('class_sections as cs','cs.id','=','s.class_section_id')
            ->join('courses as c','c.id','=','cs.course_id')
            ->select('cs.id as class_section_id','c.name as course','cs.term',
                DB::raw('SUM(r.status IN ("present","late")) as checked'))
            ->whereDate('s.start_at', $today)
            ->groupBy('cs.id','c.name','cs.term')
            ->orderByDesc('checked')
            ->limit(3)
            ->get();

        // 5) Biểu đồ cột: tình trạng điểm danh theo ngày (7 ngày gần nhất)
        $days = collect(range(6,0))->map(fn($i)=> Carbon::today()->subDays($i));
        $barLabels = $days->map(fn($d)=> $d->shortEnglishDayOfWeek)->values(); // Mon..Sun

        $barValues = $days->map(function($d){
            return DB::table('attendance_records as r')
                ->join('attendance_sessions as s','s.id','=','r.attendance_session_id')
                ->whereDate('s.start_at', $d)
                ->whereIn('r.status', ['present','late'])
                ->count();
        })->values();

        // 6) Doughnut: phân bố present/late/absent hôm nay
        $distToday = DB::table('attendance_records as r')
            ->join('attendance_sessions as s','s.id','=','r.attendance_session_id')
            ->whereDate('s.start_at', $today)
            ->select('r.status', DB::raw('count(*) as c'))
            ->groupBy('r.status')
            ->pluck('c','status');

        $donut = [
            'present' => (int)($distToday['present'] ?? 0),
            'late'    => (int)($distToday['late'] ?? 0),
            'absent'  => (int)($distToday['absent'] ?? 0),
        ];

        return view('dashboard', [
            'studentsCheckedToday' => $studentsCheckedToday,
            'classesToday'         => $classesToday,
            'attendanceRate'       => $attendanceRate,
            'topClasses'           => $topClasses,
            'barLabels'            => $barLabels,
            'barValues'            => $barValues,
            'donut'                => $donut,
        ]);
    }
}
