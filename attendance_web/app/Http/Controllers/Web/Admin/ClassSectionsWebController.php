<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{ClassSection, Course, Teacher, Major};
use Illuminate\Http\Request;

class ClassSectionsWebController extends Controller
{
    public function index(Request $r)
    {
        $q = ClassSection::with(['course','teacher.user','major']);
        if ($cid = $r->get('course_id'))  $q->where('course_id',$cid);
        if ($tid = $r->get('teacher_id')) $q->where('teacher_id',$tid);
        $sections = $q->paginate(15)->withQueryString();

        $courses  = Course::orderBy('code')->get(['id','code','name']);
        $teachers = Teacher::with('user')->orderBy('id')->get();
        return view('admin.class_sections.index', compact('sections','courses','teachers'));
    }

    public function create()
    {
        $courses  = Course::orderBy('code')->get(['id','code','name']);
        $teachers = Teacher::with('user')->orderBy('id')->get();
        $majors   = class_exists(Major::class) ? Major::orderBy('name')->get() : collect();
        return view('admin.class_sections.create', compact('courses','teachers','majors'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'course_id'=>'required|exists:courses,id',
            'teacher_id'=>'required|exists:teachers,id',
            'major_id'=>'nullable|exists:majors,id',
            'term'=>'nullable|string|max:30',
            'room'=>'nullable|string|max:50',
            'capacity'=>'nullable|integer|min:1|max:500',
            'start_date'=>'nullable|date',
            'end_date'=>'nullable|date|after_or_equal:start_date',
        ]);
        ClassSection::create($data);
        return redirect()->route('admin.class-sections.index')->with('ok','Đã tạo lớp học phần');
    }

    public function edit(ClassSection $class_section)
    {
        $courses  = Course::orderBy('code')->get(['id','code','name']);
        $teachers = Teacher::with('user')->orderBy('id')->get();
        $majors   = class_exists(Major::class) ? Major::orderBy('name')->get() : collect();
        return view('admin.class_sections.edit', [
            'section'=>$class_section->load(['course','teacher.user','major']),
            'courses'=>$courses,'teachers'=>$teachers,'majors'=>$majors
        ]);
    }

    public function update(Request $r, ClassSection $class_section)
    {
        $data = $r->validate([
            'course_id'=>'required|exists:courses,id',
            'teacher_id'=>'required|exists:teachers,id',
            'major_id'=>'nullable|exists:majors,id',
            'term'=>'nullable|string|max:30',
            'room'=>'nullable|string|max:50',
            'capacity'=>'nullable|integer|min:1|max:500',
            'start_date'=>'nullable|date',
            'end_date'=>'nullable|date|after_or_equal:start_date',
        ]);
        $class_section->update($data);
        return back()->with('ok','Đã cập nhật');
    }

    public function destroy(ClassSection $class_section)
    {
        $class_section->delete();
        return back()->with('ok','Đã xoá lớp học phần');
    }
}
