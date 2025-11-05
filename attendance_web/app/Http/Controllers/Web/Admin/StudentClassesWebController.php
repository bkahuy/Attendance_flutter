<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{StudentClass, Major, Faculty};
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class StudentClassesWebController extends Controller
{
    public function index(Request $r)
    {
        $q = StudentClass::with(['major.faculty'])->orderBy('id','asc');

        if ($s = $r->get('q'))        $q->where('name','like',"%{$s}%");
        if ($m = $r->get('major_id')) $q->where('major_id',$m);
        if ($f = $r->get('faculty_id')){
            $q->whereHas('major', fn($w)=>$w->where('faculty_id',$f));
        }

        $classes   = $q->paginate(10)->withQueryString();
        $majors    = Major::orderBy('name')->get(['id','name','faculty_id']);
        $faculties = Faculty::orderBy('name')->get(['id','name']);

        return view('admin.classes.index', compact('classes','majors','faculties'));
    }

    public function create()
    {
        $majors    = Major::orderBy('name')->get(['id','name','faculty_id']);
        $faculties = Faculty::orderBy('name')->get(['id','name']);
        return view('admin.classes.create', compact('majors','faculties'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'name'     => ['required','string','max:120','unique:classes,name'],
            'major_id' => ['required','exists:majors,id'],
        ]);
        StudentClass::create($data);
        return redirect()->route('admin.classes.index')->with('ok','Đã thêm lớp chính khoá');
    }

    public function edit($id)
    {
        $class     = StudentClass::with('major.faculty')->findOrFail($id);
        $majors    = Major::orderBy('name')->get(['id','name','faculty_id']);
        $faculties = Faculty::orderBy('name')->get(['id','name']);
        return view('admin.classes.edit', compact('class','majors','faculties'));
    }

    public function update(Request $r, $id)
    {
        $class = StudentClass::findOrFail($id);
        $data = $r->validate([
            'name'     => ['required','string','max:120', Rule::unique('classes','name')->ignore($class->id)],
            'major_id' => ['required','exists:majors,id'],
        ]);
        $class->update($data);
        return back()->with('ok','Đã cập nhật lớp');
    }

    public function destroy($id)
    {
        StudentClass::destroy($id);
        return back()->with('ok','Đã xoá lớp');
    }
}
