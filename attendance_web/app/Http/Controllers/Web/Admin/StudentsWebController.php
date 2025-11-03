<?php

namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\{Student, User};
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class StudentsWebController extends Controller
{
    public function index(Request $r)
    {
        $dir = $r->get('dir','asc') === 'desc' ? 'desc' : 'asc';

        $q = Student::with('user')->orderBy('id', $dir);

        // toolbar filters
        if ($s = $r->get('search')) {
            $q->where(function($w) use ($s){
                $w->where('student_code','like',"%$s%")
                    ->orWhereHas('user', fn($x)=>$x->where('name','like',"%$s%")
                        ->orWhere('email','like',"%$s%"));
            });
        }
        if ($code = $r->get('student_code')) { $q->where('student_code','like',"%$code%"); }
        if ($fac  = $r->get('faculty'))      { $q->where('faculty',$fac); }
        if ($cls  = $r->get('class_name'))   { $q->where('class_name',$cls); }

        $students = $q->paginate(20)->withQueryString();
        return view('admin.students.index', compact('students','dir'));
    }

    public function create()
    {
        $classes   = ['CNTT1','CNTT2','KTPM1','KTPM2','HTTT1'];
        $faculties = ['Công nghệ thông tin','Kinh tế','Xây dựng'];
        return view('admin.students.create', compact('classes','faculties'));
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'name'         => ['required','string','max:120'],
            'email'        => ['required','email','max:150','unique:users,email'],
            'student_code' => ['required','string','max:50','unique:students,student_code'],
            'faculty'      => ['nullable','string','max:100'],
            'class_name'   => ['nullable','string','max:50'],
        ]);

        $user = User::create([
            'name'=>$data['name'], 'email'=>$data['email'],
            'password'=>bcrypt('12345678'), 'role'=>'student', 'status'=>'active'
        ]);

        Student::create([
            'user_id'=>$user->id,
            'student_code'=>$data['student_code'],
            'faculty'=>$data['faculty'] ?? null,
            'class_name'=>$data['class_name'] ?? null,
        ]);

        return redirect()->route('admin.students.index')->with('ok','Đã thêm sinh viên');
    }

    public function edit(Student $student)
    {
        $student->load('user');
        $classes   = ['CNTT1','CNTT2','KTPM1','KTPM2','HTTT1'];
        $faculties = ['Công nghệ thông tin','Kinh tế','Xây dựng'];
        return view('admin.students.edit', compact('student','classes','faculties'));
    }

    public function update(Request $r, Student $student)
    {
        $data = $r->validate([
            'name'         => ['required','string','max:120'],
            'email'        => ['required','email','max:150', Rule::unique('users','email')->ignore($student->user_id)],
            'student_code' => ['required','string','max:50', Rule::unique('students','student_code')->ignore($student->id)],
            'faculty'      => ['nullable','string','max:100'],
            'class_name'   => ['nullable','string','max:50'],
        ]);

        $student->user->update(['name'=>$data['name'],'email'=>$data['email']]);
        $student->update([
            'student_code'=>$data['student_code'],
            'faculty'=>$data['faculty'] ?? null,
            'class_name'=>$data['class_name'] ?? null,
        ]);

        return back()->with('ok','Đã cập nhật');
    }

    public function destroy(Student $student)
    {
        $student->delete();
        return back()->with('ok','Đã xoá sinh viên');
    }
}
