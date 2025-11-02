<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\Schedule;
use Illuminate\Http\Request;


class SchedulesController extends Controller
{
    public function store(\Illuminate\Http\Request $r)
    {
        $data = $r->validate([
            'class_section_id' => ['required','exists:class_sections,id'],
            'start_time'       => ['required','date_format:H:i'],
            'end_time'         => ['required','date_format:H:i','after:start_time'],
            'recurring_flag'   => ['nullable','boolean'],
            'date'             => ['nullable','date'],
            'weekday'          => ['nullable','integer','between:0,6'],
        ]);

        $payload = [
            'class_section_id' => $data['class_section_id'],
            'start_time'       => $data['start_time'],
            'end_time'         => $data['end_time'],
            'recurring_flag'   => !empty($data['recurring_flag']),
        ];

        if (!empty($payload['recurring_flag'])) {
            $payload['weekday'] = $data['weekday'];
            $payload['date'] = null;
        } else {
            $payload['date'] = $data['date'];
            $payload['weekday'] = null;
        }

        \App\Models\Schedule::create($payload);
        return redirect()->route('admin.schedules.index')->with('ok','Đã tạo lịch');
    }

    public function update(\Illuminate\Http\Request $r, $id)
    {
        $schedule = \App\Models\Schedule::findOrFail($id);

        $data = $r->validate([
            'class_section_id' => ['required','exists:class_sections,id'],
            'start_time'       => ['required','date_format:H:i'],
            'end_time'         => ['required','date_format:H:i','after:start_time'],
            'recurring_flag'   => ['nullable','boolean'],
            'date'             => ['nullable','date'],
            'weekday'          => ['nullable','integer','between:0,6'],
        ]);

        $payload = [
            'class_section_id' => $data['class_section_id'],
            'start_time'       => $data['start_time'],
            'end_time'         => $data['end_time'],
            'recurring_flag'   => !empty($data['recurring_flag']),
        ];

        if (!empty($payload['recurring_flag'])) {
            $payload['weekday'] = $data['weekday'];
            $payload['date'] = null;
        } else {
            $payload['date'] = $data['date'];
            $payload['weekday'] = null;
        }

        $schedule->update($payload);
        return redirect()->route('admin.schedules.index')->with('ok','Đã cập nhật lịch');
    }



    public function destroy($id)
    {
        Schedule::destroy($id);
        return response()->json(['message'=>'Deleted']);
    }
}
