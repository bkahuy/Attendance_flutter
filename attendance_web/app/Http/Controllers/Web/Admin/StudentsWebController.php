<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{Student, User, Faculty, StudentClass};
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class StudentsWebController extends Controller
{
    public function index(Request $r)
    {
        $dir = $r->get('dir','asc') === 'desc' ? 'desc' : 'asc';
        $per = 10;

        $q = Student::with(['user','studentClass.major.faculty'])
            ->orderBy('id', $dir);

        if ($s = $r->get('search')) {
            $q->where(function($w) use ($s){
                $w->where('student_code','like',"%$s%")
                    ->orWhereHas('user', function($x) use ($s){
                        $x->where('name','like',"%$s%")
                            ->orWhere('email','like',"%$s%")
                            ->orWhere('phone','like',"%$s%");
                    });
            });
        }
        if ($code = $r->get('student_code')) {
            $q->where('student_code','like',"%$code%");
        }
        if ($classId = $r->get('class_id')) {
            $q->where('class_id', $classId);
        }
        if ($facultyId = $r->get('faculty_id')) {
            $q->whereHas('studentClass.major', function ($m) use ($facultyId) {
                $m->where('faculty_id', $facultyId);
            });
        }

        $students  = $q->paginate($per)->withQueryString();
        $faculties = Faculty::orderBy('name')->get(['id','name']);
        $classes   = StudentClass::orderBy('name')->get(['id','name']);

        return view('admin.students.index', compact('students','dir','faculties','classes'));
    }

    public function create()
    {
        $classes = StudentClass::with('major.faculty')->orderBy('name')->get();
        return view('admin.students.create', compact('classes'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'name'         => ['required','string','max:120'],
            'email'        => ['required','email','max:150','unique:users,email'],
            'phone'        => ['nullable','string','max:30'], // <= phone
            'student_code' => ['required','string','max:50','unique:students,student_code'],
            'class_id'     => ['nullable','exists:classes,id'],
        ]);

        return DB::transaction(function () use ($data) {
            $user = User::create([
                'name'     => $data['name'],
                'email'    => strtolower(trim($data['email'])),
                'phone'    => $data['phone'] ?? null,
                'password' => bcrypt('12345678'),
                'role'     => 'student',
                'status'   => 'active',
            ]);

            Student::create([
                'user_id'      => $user->id,
                'student_code' => $data['student_code'],
                'class_id'     => $data['class_id'] ?? null,
            ]);

            return redirect()->route('admin.students.index')->with('ok','Đã thêm sinh viên');
        });
    }

    public function edit(Student $student)
    {
        $student->load(['user','studentClass.major.faculty']);
        $classes = StudentClass::with('major.faculty')->orderBy('name')->get();
        return view('admin.students.edit', compact('student','classes'));
    }

    public function update(Request $r, Student $student)
    {
        $data = $r->validate([
            'name'         => ['required','string','max:120'],
            'email'        => ['required','email', Rule::unique('users','email')->ignore($student->user_id)],
            'phone'        => ['nullable','string','max:30'], // <= phone
            'student_code' => ['required','string','max:50', Rule::unique('students','student_code')->ignore($student->id)],
            'class_id'     => ['nullable','exists:classes,id'],
        ]);

        return DB::transaction(function () use ($student, $data) {
            $student->user->update([
                'name'  => $data['name'],
                'email' => strtolower(trim($data['email'])),
                'phone' => $data['phone'] ?? null,
            ]);

            $student->update([
                'student_code' => $data['student_code'],
                'class_id'     => $data['class_id'] ?? null,
            ]);

            return back()->with('ok','Đã cập nhật sinh viên');
        });
    }

    public function destroy(Student $student)
    {
        $student->delete();
        return back()->with('ok','Đã xoá sinh viên');
    }
}
