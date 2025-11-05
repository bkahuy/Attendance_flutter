<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{Teacher, User, Department, Faculty};
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\DB;

class TeachersWebController extends Controller
{
    public function index(Request $r)
    {
        $per = 10;

        $q = Teacher::with(['user','department.faculty'])->orderBy('id', 'asc');

        if ($s = $r->get('search')) {
            $q->where(function($w) use ($s){
                $w->where('teacher_code','like',"%$s%")
                    ->orWhereHas('user', function($x) use ($s){
                        $x->where('name','like',"%$s%")
                            ->orWhere('email','like',"%$s%")
                            ->orWhere('phone','like',"%$s%");
                    });
            });
        }
        if ($code = $r->get('teacher_code'))   { $q->where('teacher_code','like',"%$code%"); }
        if ($dep  = $r->get('department_id'))  { $q->where('department_id',$dep); }
        if ($fac  = $r->get('faculty_id')) {
            $q->whereHas('department', fn($x)=>$x->where('faculty_id',$fac));
        }

        $teachers    = $q->paginate($per)->withQueryString();
        $departments = \App\Models\Department::with('faculty')->orderBy('name')->get(['id','name']);
        $faculties   = Faculty::orderBy('name')->get(['id','name']);

        return view('admin.teachers.index', compact('teachers','departments','faculties'));
    }

    public function create()
    {
        $departments = Department::with('faculty')->orderBy('name')->get(['id','name']);
        return view('admin.teachers.create', compact('departments'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'name'          => ['required','string','max:120'],
            'email'         => ['required','email','max:150','unique:users,email'],
            'phone'         => ['nullable','string','max:30'], // <= thêm phone
            'teacher_code'  => ['required','string','max:50','unique:teachers,teacher_code'],
            'department_id' => ['required','exists:departments,id'],
        ]);

        return DB::transaction(function () use ($data) {
            $email = strtolower(trim($data['email']));

            $user = User::create([
                'name'     => $data['name'],
                'email'    => $email,
                'phone'    => $data['phone'] ?? null, // <= lưu phone
                'password' => bcrypt('12345678'),
                'role'     => 'teacher',
                'status'   => 'active',
            ]);

            Teacher::create([
                'user_id'       => $user->id,
                'teacher_code'  => $data['teacher_code'],
                'department_id' => $data['department_id'],
            ]);

            return redirect()->route('admin.teachers.index')->with('ok','Đã thêm giảng viên');
        });
    }

    public function edit(Teacher $teacher)
    {
        $teacher->load(['user','department.faculty']);
        $departments = \App\Models\Department::with('faculty')->orderBy('name')->get(['id','name']);
        return view('admin.teachers.edit', compact('teacher','departments'));
    }

    public function update(Request $r, Teacher $teacher)
    {
        $data = $r->validate([
            'name'          => ['required','string','max:120'],
            'email'         => ['required','email', Rule::unique('users','email')->ignore($teacher->user_id)],
            'phone'         => ['nullable','string','max:30'], // <= thêm phone
            'teacher_code'  => ['required','string','max:50', Rule::unique('teachers','teacher_code')->ignore($teacher->id)],
            'department_id' => ['required','exists:departments,id'],
        ]);

        return DB::transaction(function () use ($teacher, $data) {
            $teacher->user->update([
                'name'  => $data['name'],
                'email' => strtolower(trim($data['email'])),
                'phone' => $data['phone'] ?? null, // <= cập nhật phone
            ]);

            $teacher->update([
                'teacher_code'  => $data['teacher_code'],
                'department_id' => $data['department_id'],
            ]);

            return back()->with('ok','Đã cập nhật giảng viên');
        });
    }

    public function destroy(Teacher $teacher)
    {
        $teacher->delete();
        return back()->with('ok','Đã xoá giảng viên');
    }
}
