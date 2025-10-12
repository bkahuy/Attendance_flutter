<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\ClassSection;
use Illuminate\Http\Request;


class ClassSectionsController extends Controller
{
    public function index(){
        return ClassSection::with(['course','teacher.user'])->paginate(50);
    }


    public function store(Request $r){
        $data = $r->validate([
            'course_id' => 'required|exists:courses,id',
            'teacher_id' => 'required|exists:teachers,id',
            'term' => 'required',
            'room' => 'nullable',
            'capacity' => 'nullable|integer|min:1',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);
        $cs = ClassSection::create($data);
        return response()->json($cs->load(['course','teacher.user']),201);
    }


    public function show($id){ return ClassSection::with(['course','teacher.user','schedules'])->findOrFail($id); }


    public function update(Request $r,$id){ $cs=ClassSection::findOrFail($id); $cs->update($r->only('course_id','teacher_id','term','room','capacity','start_date','end_date')); return $cs->load(['course','teacher.user']); }


    public function destroy($id){ ClassSection::destroy($id); return response()->json(['message'=>'Deleted']); }
}
