<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{ClassSection, Course, Teacher, Major};
use Illuminate\Http\Request;
use Carbon\Carbon;

class ClassSectionsWebController extends Controller
{
    public function index(Request $r)
    {
        $q = ClassSection::with(['course','teacher.user','major']);

        if ($cid = $r->get('course_id'))  $q->where('course_id',$cid);
        if ($tid = $r->get('teacher_id')) $q->where('teacher_id',$tid);
        if ($term = $r->get('term'))      $q->where('term', $term);

        // 10 item/trang + giữ query string để Previous/Next hoạt động đúng
        $sections = $q
            ->paginate(10)
            ->withQueryString();

        $courses  = Course::orderBy('code')->get(['id','code','name']);
        $teachers = Teacher::with('user')->orderBy('id')->get();

        $terms = ClassSection::query()
            ->select('term')->whereNotNull('term')->distinct()->orderBy('term')->pluck('term');

        return view('admin.class_sections.index', compact('sections','courses','teachers','terms'));
    }

    public function create()
    {
        $courses  = Course::orderBy('code')->get(['id','code','name']);
        $teachers = Teacher::with('user')->get();
        $majors   = class_exists(Major::class) ? Major::orderBy('name')->get() : collect();

        // gợi ý kỳ học (năm hiện tại ±1, kỳ 1/2)
        $termOptions = $this->buildTermOptions();

        return view('admin.class_sections.create', compact('courses','teachers','majors','termOptions'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'course_id'  => 'required|exists:courses,id',
            'teacher_id' => 'required|exists:teachers,id',
            'major_id'   => 'nullable|exists:majors,id',
            'term'       => 'nullable|string|max:30',
            'room'       => 'nullable|string|max:50',
            'capacity'   => 'nullable|integer|min:1|max:500',
            'start_date' => 'nullable|date',
            'end_date'   => 'nullable|date|after_or_equal:start_date',
        ]);

        ClassSection::create($data);

        return redirect()->route('admin.class-sections.index')->with('ok','Đã tạo lớp học phần');
    }

    public function edit(ClassSection $class_section)
    {
        $courses  = Course::orderBy('code')->get(['id','code','name']);
        $teachers = Teacher::with('user')->get();
        $majors   = class_exists(Major::class) ? Major::orderBy('name')->get() : collect();
        $termOptions = $this->buildTermOptions();

        return view('admin.class_sections.edit', [
            'section'     => $class_section->load(['course','teacher.user','major']),
            'courses'     => $courses,
            'teachers'    => $teachers,
            'majors'      => $majors,
            'termOptions' => $termOptions,
        ]);
    }

    public function update(Request $r, ClassSection $class_section)
    {
        $data = $r->validate([
            'course_id'  => 'required|exists:courses,id',
            'teacher_id' => 'required|exists:teachers,id',
            'major_id'   => 'nullable|exists:majors,id',
            'term'       => 'nullable|string|max:30',
            'room'       => 'nullable|string|max:50',
            'capacity'   => 'nullable|integer|min:1|max:500',
            'start_date' => 'nullable|date',
            'end_date'   => 'nullable|date|after_or_equal:start_date',
        ]);

        $class_section->update($data);

        return back()->with('ok','Đã cập nhật');
    }

    public function destroy(ClassSection $class_section)
    {
        $class_section->delete();
        return back()->with('ok','Đã xoá lớp học phần');
    }

    private function buildTermOptions(): array
    {
        $y = (int) now()->year;
        // format “2025-2026 Kỳ 1/2”
        $opts = [];
        foreach ([$y-1, $y, $y+1] as $year) {
            $opts[] = "{$year}-".($year+1)." Kỳ 1";
            $opts[] = "{$year}-".($year+1)." Kỳ 2";
        }
        // gộp thêm các term đã có trong DB cho đầy đủ
        $existing = ClassSection::whereNotNull('term')->select('term')->distinct()->pluck('term')->all();
        $all = array_values(array_unique(array_merge($existing, $opts)));
        rsort($all);
        return $all;
    }
}
