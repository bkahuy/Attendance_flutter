<?php
namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{Schedule,ClassSection};
use Illuminate\Http\Request;

class SchedulesWebController extends Controller
{
    public function store(Request $r)
    {
        $data = $r->validate([
            'class_section_id'=>'required|exists:class_sections,id',
            'date'=>'nullable|date',
            'weekday'=>'nullable|integer|min:0|max:6',
            'start_time'=>'required|date_format:H:i',
            'end_time'=>'required|date_format:H:i|after:start_time',
            'recurring_flag'=>'nullable|boolean',
            'location_lat'=>'nullable|numeric',
            'location_lng'=>'nullable|numeric',
        ]);
        // Chuẩn hoá :ss
        $data['start_time'] .= ':00';
        $data['end_time']   .= ':00';
        $data['recurring_flag'] = (int)($data['recurring_flag'] ?? 0);

        Schedule::create($data);
        return back()->with('ok','Đã thêm lịch dạy');
    }

    public function destroy($id)
    {
        Schedule::destroy($id);
        return back()->with('ok','Đã xoá lịch');
    }
}
