<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\ViewTeacherSchedule;
use Illuminate\Http\Request;


class SchedulesController extends Controller
{
    public function store(Request $r)
    {
        $data = $r->validate([
            'class_section_id' => 'required|exists:class_sections,id',
            'date' => 'nullable|date',
            'weekday' => 'nullable|integer|min:0|max:6',
            'start_time' => 'required|date_format:H:i:s',
            'end_time' => 'required|date_format:H:i:s',
            'recurring_flag' => 'boolean',
            'location_lat' => 'nullable|numeric',
            'location_lng' => 'nullable|numeric',
        ]);
        $s = ViewTeacherSchedule::create($data);
        return response()->json($s, 201);
    }


    public function destroy($id)
    {
        ViewTeacherSchedule::destroy($id);
        return response()->json(['message'=>'Deleted']);
    }
}
