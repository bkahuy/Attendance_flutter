<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\ClassSection;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Student;


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

    public function students(Request $r, ClassSection $classSection)
    {
        $limit  = max(1, (int)$r->get('limit', 50));
        $search = trim((string)$r->get('q', ''));

        // SV đang trong lớp (có pivot->enrolled_at)
        $enrolled = $classSection->students()
            ->with('user:id,name,email')
            ->orderBy('student_code')
            ->get(['students.id','students.student_code','students.class_name','students.faculty','students.user_id']);

        // SV chưa thuộc lớp
        $availableQ = Student::query()
            ->with('user:id,name,email')
            ->whereNotIn('id', $enrolled->pluck('id'));

        if ($search !== '') {
            $availableQ->where(function($qq) use ($search) {
                $qq->where('student_code','like',"%{$search}%")
                    ->orWhereHas('user', fn($u)=>$u->where('name','like',"%{$search}%"));
            });
        }

        $available = $availableQ
            ->orderBy('student_code')
            ->limit($limit)
            ->get(['id','student_code','class_name','faculty','user_id']);

        return response()->json([
            'class_section_id' => $classSection->id,
            'enrolled' => $enrolled->map(function($st){
                return [
                    'id'           => $st->id,
                    'student_code' => $st->student_code,
                    'name'         => optional($st->user)->name,
                    'email'        => optional($st->user)->email,
                    'class_name'   => $st->class_name,
                    'faculty'      => $st->faculty,
                    'enrolled_at'  => optional($st->pivot)->enrolled_at,
                ];
            }),
            'available' => $available->map(function($st){
                return [
                    'id'           => $st->id,
                    'student_code' => $st->student_code,
                    'name'         => optional($st->user)->name,
                    'email'        => optional($st->user)->email,
                    'class_name'   => $st->class_name,
                    'faculty'      => $st->faculty,
                ];
            }),
            'counts' => [
                'enrolled'  => $enrolled->count(),
                'available' => $available->count(),
            ],
        ]);
    }

    public function enrollSync(Request $r, ClassSection $classSection)
    {
        $data = $r->validate([
            'student_ids'   => 'array',
            'student_ids.*' => 'integer',
        ]);

        $ids = $data['student_ids'] ?? [];

        // Lọc id tồn tại
        $validIds = Student::whereIn('id', $ids)->pluck('id')->all();

        DB::transaction(function() use ($classSection, $validIds) {
            // Cách 1 (dựa DEFAULT CURRENT_TIMESTAMP ở DB của bạn):
            $classSection->students()->sync($validIds);

            // Nếu muốn chủ động set thời điểm ghi danh, dùng Cách 2:
            // $payload = [];
            // foreach ($validIds as $sid) { $payload[$sid] = ['enrolled_at' => now()]; }
            // $classSection->students()->sync($payload);
        });

        // Trả danh sách mới
        $enrolled = $classSection->students()
            ->with('user:id,name,email')
            ->orderBy('student_code')
            ->get(['students.id','students.student_code','students.class_name','students.faculty','students.user_id']);

        return response()->json([
            'message'          => 'Đã cập nhật danh sách sinh viên của lớp',
            'class_section_id' => $classSection->id,
            'enrolled' => $enrolled->map(function($st){
                return [
                    'id'           => $st->id,
                    'student_code' => $st->student_code,
                    'name'         => optional($st->user)->name,
                    'email'        => optional($st->user)->email,
                    'class_name'   => $st->class_name,
                    'faculty'      => $st->faculty,
                    'enrolled_at'  => optional($st->pivot)->enrolled_at,
                ];
            }),
            'count' => $enrolled->count(),
        ]);
    }


    public function show($id){ return ClassSection::with(['course','teacher.user','schedules'])->findOrFail($id); }


    public function update(Request $r,$id){ $cs=ClassSection::findOrFail($id); $cs->update($r->only('course_id','teacher_id','term','room','capacity','start_date','end_date')); return $cs->load(['course','teacher.user']); }


    public function destroy($id){ ClassSection::destroy($id); return response()->json(['message'=>'Deleted']); }
}
