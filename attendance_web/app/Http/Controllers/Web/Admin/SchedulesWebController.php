<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\ClassSection;
use App\Models\Schedule;
use Carbon\Carbon;
use Illuminate\Http\Request;

class SchedulesWebController extends Controller
{
    public function index(Request $r)
    {
        $anchor = $r->input('date'); // yyyy-mm-dd
        $monday = $anchor ? Carbon::parse($anchor)->startOfWeek(Carbon::MONDAY)
            : now()->startOfWeek(Carbon::MONDAY);
        $sunday = (clone $monday)->endOfWeek(Carbon::SUNDAY);

        $rows = Schedule::with(['classSection.course','classSection.teacher.user'])
            ->where(function ($q) use ($monday, $sunday) {
                $q->where(function ($x) use ($monday, $sunday) {
                    $x->where('recurring_flag', 0)
                        ->whereBetween('date', [$monday->toDateString(), $sunday->toDateString()]);
                })
                    ->orWhere('recurring_flag', 1);
            })
            ->orderBy('start_time')
            ->get();

        // optional filters từ toolbar
        if ($csId = $r->get('class_section_id')) {
            $rows = $rows->where('class_section_id', (int)$csId);
        }
        if ($tId = $r->get('teacher_id')) {
            $rows = $rows->filter(fn($s) => optional($s->classSection)->teacher_id == (int)$tId);
        }

        // 7 ngày
        $days = [];
        for ($i=0; $i<7; $i++) {
            $d = (clone $monday)->addDays($i);
            $days[$d->toDateString()] = ['date'=>$d, 'items'=>[]];
        }

        // gom + khử lặp
        foreach ($rows as $sc) {
            if ($sc->recurring_flag) {
                foreach ($days as $key => $bucket) {
                    $weekdayMySQL = $bucket['date']->isoWeekday() - 1; // 0..6
                    if ($weekdayMySQL === (int)$sc->weekday) {
                        $days[$key]['items'][$sc->id] = $sc;
                    }
                }
            } else {
                $key = Carbon::parse($sc->date)->toDateString();
                if (isset($days[$key])) {
                    $days[$key]['items'][$sc->id] = $sc;
                }
            }
        }

        return view('admin.schedules.index', compact('days','monday','sunday'));
    }

    public function create()
    {
        $classSections = ClassSection::with('course')->orderBy('id')->get();
        return view('admin.schedules.create', compact('classSections'));
    }

    public function edit($id)
    {
        $schedule = Schedule::with('classSection.course')->findOrFail($id);
        $classSections = ClassSection::with('course')->orderBy('id')->get();
        return view('admin.schedules.edit', compact('schedule','classSections'));
    }
}
