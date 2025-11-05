<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{Course, Department};
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CoursesWebController extends Controller
{
    public function index(Request $r)
    {
        $q = Course::with('department')->orderBy('code');

        if ($s = $r->get('q')) {
            $q->where(function ($w) use ($s) {
                $w->where('code','like',"%$s%")
                    ->orWhere('name','like',"%$s%");
            });
        }
        if ($dep = $r->get('department_id')) {
            $q->where('department_id',$dep);
        }

        $courses     = $q->paginate(10)->withQueryString();
        $departments = Department::orderBy('name')->get(['id','name']);

        return view('admin.courses.index', compact('courses','departments'));
    }

    public function create()
    {
        $departments = Department::orderBy('name')->get(['id','name']);
        return view('admin.courses.create', compact('departments'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'code'          => ['required','string','max:50','unique:courses,code'],
            'name'          => ['required','string','max:255'],
            'credits'       => ['required','integer','min:1','max:10'],
            'department_id' => ['nullable','exists:departments,id'],
        ]);
        $data['department_id'] = $r->filled('department_id') ? (int)$r->department_id : null;

        Course::create($data);

        return redirect()->route('admin.courses.index')->with('ok','Đã thêm môn học');
    }

    public function edit($id)
    {
        $course      = Course::findOrFail($id);
        $departments = Department::orderBy('name')->get(['id','name']);
        return view('admin.courses.edit', compact('course','departments'));
    }

    public function update(Request $r, $id)
    {
        $course = Course::findOrFail($id);

        $data = $r->validate([
            'code'          => ['required','string','max:50',"unique:courses,code,{$course->id}"],
            'name'          => ['required','string','max:255'],
            'credits'       => ['required','integer','min:1','max:10'],
            'department_id' => ['nullable','exists:departments,id'],
        ]);
        $data['department_id'] = $r->filled('department_id') ? (int)$r->department_id : null;

        $course->update($data);

        return redirect()->route('admin.courses.index')->with('ok','Đã cập nhật');
    }

    public function show($id)
    {
        $course = Course::with('department')->findOrFail($id);
        return view('admin.courses.show', compact('course'));
    }

    public function destroy($id)
    {
        Course::findOrFail($id)->delete();
        return back()->with('ok','Đã xoá môn học');
    }
}
