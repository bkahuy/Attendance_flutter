<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{Teacher, User, Department};
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TeachersWebController extends Controller
{
    public function index(Request $r)
    {
        $q = Teacher::with(['user','department'])->orderBy('id');

        if ($s = $r->get('search')) {
            $q->where(function($w) use ($s){
                $w->where('teacher_code','like',"%$s%")
                    ->orWhereHas('user', fn($x)=>$x->where('name','like',"%$s%")
                        ->orWhere('email','like',"%$s%"));
            });
        }
        if ($code = $r->get('teacher_code'))   { $q->where('teacher_code','like',"%$code%"); }
        if ($dep  = $r->get('department_id'))  { $q->where('department_id',$dep); }

        $teachers = $q->paginate(15)->withQueryString();
        return view('admin.teachers.index', compact('teachers'));
    }

    public function create()
    {
        $departments = Department::orderBy('name')->get();
        return view('admin.teachers.create', compact('departments'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'name'          => ['required','string','max:120'],
            'email'         => ['required','email','max:150','unique:users,email'],
            'teacher_code'  => ['required','string','max:50','unique:teachers,teacher_code'],
            'department_id' => ['nullable','exists:departments,id'],
        ]);

        $user = User::create([
            'name'=>$data['name'], 'email'=>$data['email'],
            'password'=>bcrypt('12345678'), 'role'=>'teacher', 'status'=>'active'
        ]);

        Teacher::create([
            'user_id'=>$user->id,
            'teacher_code'=>$data['teacher_code'],
            'department_id'=>$data['department_id'] ?? null,
        ]);

        return redirect()->route('admin.teachers.index')->with('ok','Đã thêm giảng viên');
    }

    public function edit(Teacher $teacher)
    {
        $teacher->load(['user','department']);
        $departments = Department::orderBy('name')->get();
        return view('admin.teachers.edit', compact('teacher','departments'));
    }

    public function update(Request $r, Teacher $teacher)
    {
        $data = $r->validate([
            'name'          => ['required','string','max:120'],
            'email'         => ['required','email', Rule::unique('users','email')->ignore($teacher->user_id)],
            'teacher_code'  => ['required','string','max:50', Rule::unique('teachers','teacher_code')->ignore($teacher->id)],
            'department_id' => ['nullable','exists:departments,id'],
        ]);

        $teacher->user->update(['name'=>$data['name'], 'email'=>$data['email']]);
        $teacher->update([
            'teacher_code'=>$data['teacher_code'],
            'department_id'=>$data['department_id'] ?? null,
        ]);

        return back()->with('ok','Đã cập nhật');
    }

    public function destroy(Teacher $teacher)
    {
        $teacher->delete();
        return back()->with('ok','Đã xoá giảng viên');
    }
}
