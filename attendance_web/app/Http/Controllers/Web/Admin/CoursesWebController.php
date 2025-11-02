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
        if ($s = $r->get('search')) {
            $q->where('code','like',"%$s%")->orWhere('name','like',"%$s%");
        }
        $courses = $q->paginate(15)->withQueryString();
        return view('admin.courses.index', compact('courses'));
    }

    public function create() {
        $departments = Department::orderBy('name')->get();
        return view('admin.courses.create', compact('departments'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'code'=>['required','max:20','unique:courses,code'],
            'name'=>['required','max:150'],
            'credits'=>['required','integer','min:1','max:10'],
            'department_id'=>['nullable','exists:departments,id'],
        ]);
        Course::create($data);
        return redirect()->route('admin.courses.index')->with('ok','Đã thêm môn học');
    }

    public function edit(Course $course) {
        $departments = Department::orderBy('name')->get();
        return view('admin.courses.edit', compact('course','departments'));
    }

    public function update(Request $r, Course $course)
    {
        $data = $r->validate([
            'code'=>['required','max:20', Rule::unique('courses','code')->ignore($course->id)],
            'name'=>['required','max:150'],
            'credits'=>['required','integer','min:1','max:10'],
            'department_id'=>['nullable','exists:departments,id'],
        ]);
        $course->update($data);
        return back()->with('ok','Đã cập nhật');
    }

    public function destroy(Course $course)
    {
        $course->delete();
        return back()->with('ok','Đã xoá môn học');
    }
}
