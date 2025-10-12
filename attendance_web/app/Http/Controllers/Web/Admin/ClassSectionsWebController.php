<?php
namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{ClassSection,Course,Teacher,Student};
use Illuminate\Http\Request;

class ClassSectionsWebController extends Controller
{
    public function index()
    {
        $classes = ClassSection::with(['course','teacher.user'])->orderByDesc('id')->paginate(15);
        return view('admin.class_sections.index', compact('classes'));
    }

    public function create()
    {
        return view('admin.class_sections.create', [
            'courses' => Course::orderBy('code')->get(),
            'teachers'=> Teacher::with('user')->orderBy('id','desc')->get(),
        ]);
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'course_id'=>'required|exists:courses,id',
            'teacher_id'=>'required|exists:teachers,id',
            'term'=>'required',
            'room'=>'nullable',
            'capacity'=>'nullable|integer|min:1',
            'start_date'=>'nullable|date',
            'end_date'=>'nullable|date',
        ]);
        ClassSection::create($data);
        return redirect()->route('class-sections.index')->with('ok','Đã tạo lớp học phần');
    }

    public function edit($id)
    {
        return view('admin.class_sections.edit', [
            'cls' => ClassSection::findOrFail($id),
            'courses' => Course::orderBy('code')->get(),
            'teachers'=> Teacher::with('user')->get(),
        ]);
    }

    public function update(Request $r, $id)
    {
        $cs = ClassSection::findOrFail($id);
        $cs->update($r->validate([
            'course_id'=>'required|exists:courses,id',
            'teacher_id'=>'required|exists:teachers,id',
            'term'=>'required',
            'room'=>'nullable',
            'capacity'=>'nullable|integer|min:1',
            'start_date'=>'nullable|date',
            'end_date'=>'nullable|date',
        ]));
        return redirect()->route('class-sections.index')->with('ok','Đã cập nhật');
    }

    public function destroy($id)
    {
        ClassSection::destroy($id);
        return back()->with('ok','Đã xoá');
    }
}
