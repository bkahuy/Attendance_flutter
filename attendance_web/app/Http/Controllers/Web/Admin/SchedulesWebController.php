<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\ClassSection;
use App\Models\Schedule;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class SchedulesWebController extends Controller
{
    public function index(Request $r)
    {
        $anchor = $r->input('date'); // yyyy-mm-dd
        $monday = $anchor ? Carbon::parse($anchor)->startOfWeek(Carbon::MONDAY) : now()->startOfWeek(Carbon::MONDAY);
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

        // Optional filters
        if ($csId = $r->get('class_section_id')) {
            $rows = $rows->where('class_section_id', (int)$csId);
        }
        if ($tId = $r->get('teacher_id')) {
            $rows = $rows->filter(fn($s) => optional($s->classSection)->teacher_id == (int)$tId);
        }
        if ($courseId = $r->get('course_id')) {
            $rows = $rows->filter(fn($s) => optional($s->classSection?->course)->id == (int)$courseId);
        }

        $days = [];
        for ($i=0; $i<7; $i++) {
            $d = (clone $monday)->addDays($i);
            $days[$d->toDateString()] = ['date'=>$d, 'items'=>[]];
        }

        // gom vào 7 ngày hiển thị
        foreach ($rows as $sc) {
            if ($sc->recurring_flag) {
                foreach ($days as $key => $bucket) {
                    $weekdayMySQL = $bucket['date']->isoWeekday() - 1; // 0..6
                    if ($weekdayMySQL === (int)$sc->weekday) {
                        $days[$key]['items'][$sc->id] = $sc;
                    }
                }
            } else {
                $key = optional($sc->date)->toDateString();
                if ($key && isset($days[$key])) {
                    $days[$key]['items'][$sc->id] = $sc;
                }
            }
        }

        $courses = \App\Models\Course::orderBy('code')->get();
        $teachers = \App\Models\Teacher::with('user')->orderBy('id')->get();

        return view('admin.schedules.index', compact('days','monday','sunday','courses','teachers'));
    }

    public function create()
    {
        $classSections = ClassSection::with('course')->orderBy('id')->get();
        return view('admin.schedules.create', compact('classSections'));
    }

    public function store(Request $r)
    {
        // Checkbox -> boolean
        $r->merge(['recurring_flag' => $r->boolean('recurring_flag')]);

        // Validate
        $data = $r->validate([
            'class_section_id' => ['required','integer', Rule::exists('class_sections','id')],
            'start_time'       => ['required','date_format:H:i'],
            'end_time'         => ['required','date_format:H:i','after:start_time'],
            'recurring_flag'   => ['boolean'],

            // one-shot
            'date'             => ['nullable','date'],

            // weekly multi-days
            'weekday'          => ['nullable','integer','between:0,6'], // fallback form cũ
            'weekdays'         => ['nullable','array'],
            'weekdays.*'       => ['integer','between:0,6'],

            // khoảng tuần (tuỳ chọn)
            'week_start'       => ['nullable','date'],
            'week_end'         => ['nullable','date','after_or_equal:week_start'],
        ]);

        $payload = [
            'class_section_id' => $data['class_section_id'],
            'start_time'       => $data['start_time'].':00',
            'end_time'         => $data['end_time'].':00',
            'recurring_flag'   => !empty($data['recurring_flag']),
        ];

        if (!empty($payload['recurring_flag'])) {
            // ---- LẶP TUẦN ----
            $days = $data['weekdays'] ?? (isset($data['weekday']) ? [$data['weekday']] : []);
            $days = array_values(array_unique(array_map('intval', $days)));

            if (empty($days)) {
                return back()->withErrors(['weekdays' => 'Bật lặp tuần thì phải chọn ít nhất 1 thứ.'])->withInput();
            }

            $hasRange = !empty($data['week_start']) && !empty($data['week_end']);

            if (!$hasRange) {
                // 2.1) Lặp vô hạn → tạo 1 bản ghi/thu với recurring_flag = 1
                foreach ($days as $wd) {
                    $row = $payload;
                    $row['weekday'] = $wd;
                    $row['date']    = null;
                    \App\Models\Schedule::create($row);
                }
            } else {
                // 2.2) Lặp theo khoảng tuần → sinh N bản ghi one-shot (recurring_flag = 0)
                $from = Carbon::parse($data['week_start'])->startOfWeek(Carbon::MONDAY);
                $to   = Carbon::parse($data['week_end'])->endOfWeek(Carbon::SUNDAY);

                DB::transaction(function () use ($from, $to, $days, $payload) {
                    $cursor = $from->copy();
                    while ($cursor->lte($to)) {
                        $weekdayMySQL = $cursor->isoWeekday() - 1; // 0..6
                        if (in_array($weekdayMySQL, $days, true)) {
                            $row = $payload;
                            $row['recurring_flag'] = false;
                            $row['date']    = $cursor->toDateString();
                            $row['weekday'] = null;
                            \App\Models\Schedule::create($row);
                        }
                        $cursor->addDay();
                    }
                });
            }
        } else {
            // ---- ONE-SHOT ----
            if (empty($data['date'])) {
                return back()->withErrors(['date' => 'Hãy chọn ngày cho lịch one-shot.'])->withInput();
            }
            $row = $payload;
            $row['recurring_flag'] = false;
            $row['date']    = $data['date'];
            $row['weekday'] = null;
            \App\Models\Schedule::create($row);
        }

        return redirect()->route('admin.schedules.index')->with('success','Đã thêm lịch học.');
    }
    public function edit($id)
    {
        $schedule = Schedule::with('classSection.course')->findOrFail($id);
        $classSections = ClassSection::with('course')->orderBy('id')->get();
        return view('admin.schedules.edit', compact('schedule','classSections'));
    }
    public function update(Request $r, $id)
    {
        $schedule = Schedule::findOrFail($id);

        $r->merge(['recurring_flag' => $r->boolean('recurring_flag')]);

        $data = $r->validate([
            'class_section_id' => ['required','integer', Rule::exists('class_sections','id')],
            'start_time'       => ['required','date_format:H:i'],
            'end_time'         => ['required','date_format:H:i','after:start_time'],
            'recurring_flag'   => ['boolean'],
            'date'             => ['nullable','date'],
            'weekday'          => ['nullable','integer','between:0,6'],
        ]);

        $schedule->update([
            'class_section_id' => $data['class_section_id'],
            'start_time'       => $data['start_time'].':00',
            'end_time'         => $data['end_time'].':00',
            'recurring_flag'   => !empty($data['recurring_flag']),
            'date'             => !empty($data['recurring_flag']) ? null : ($data['date'] ?? null),
            'weekday'          => !empty($data['recurring_flag']) ? ($data['weekday'] ?? null) : null,
        ]);

        return redirect()->route('admin.schedules.index')->with('success','Đã cập nhật.');
    }

    public function destroy($id)
    {
        $schedule = Schedule::findOrFail($id);
        $schedule->delete();
        return back()->with('success','Đã xoá lịch.');
    }
}
