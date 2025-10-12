<?php
namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\Request;

class CoursesWebController extends Controller
{
    public function index()
    {
        $courses = Course::orderBy('code')->paginate(20);
        return view('admin.courses.index', compact('courses'));
    }

    public function create(){ return view('admin.courses.create'); }

    public function store(Request $r)
    {
        Course::create($r->validate([
            'code'=>'required|unique:courses',
            'name'=>'required',
            'credits'=>'required|integer|min:1'
        ]));
        return redirect()->route('courses.index')->with('ok','Đã tạo môn học');
    }

    public function edit($id)
    {
        $course = Course::findOrFail($id);
        return view('admin.courses.edit', compact('course'));
    }

    public function update(Request $r, $id)
    {
        $c = Course::findOrFail($id);
        $c->update($r->validate([
            'code'=>"required|unique:courses,code,$id",
            'name'=>'required',
            'credits'=>'required|integer|min:1'
        ]));
        return redirect()->route('courses.index')->with('ok','Đã cập nhật');
    }

    public function destroy($id)
    {
        Course::destroy($id);
        return back()->with('ok','Đã xoá');
    }
}
