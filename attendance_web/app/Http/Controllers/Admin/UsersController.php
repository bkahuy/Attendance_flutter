<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;


class UsersController extends Controller
{
    public function index() { return User::paginate(20); }


    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:150|unique:users,email',
            'password' => 'required|min:8',
            'role' => 'required|in:admin,teacher,student',

            // field mở rộng cho student
            'student_code' => 'nullable|string|max:50|unique:students,student_code',
            'faculty' => 'nullable|string|max:100',
            'class_name' => 'nullable|string|max:100',

            // field mở rộng cho teacher
            'department' => 'nullable|string|max:100',
            'title' => 'nullable|string|max:100',
        ]);

        DB::transaction(function() use ($data) {
            $user = \App\Models\User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => bcrypt($data['password']),
                'role' => $data['role'],
                'status' => 'active',
            ]);

            if ($data['role'] === 'student') {
                \App\Models\Student::create([
                    'user_id' => $user->id,
                    'student_code' => $data['student_code'] ?? null,
                    'faculty' => $data['faculty'] ?? null,
                    'class_name' => $data['class_name'] ?? null,
                ]);
            } elseif ($data['role'] === 'teacher') {
                \App\Models\Teacher::create([
                    'user_id' => $user->id,
                    'department' => $data['department'] ?? null,
                    'title' => $data['title'] ?? null,
                ]);
            }
        });

        return redirect()->route('users.index')->with('ok','Tạo tài khoản thành công');
    }

    public function update(Request $request, \App\Models\User $user)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:150|unique:users,email,'.$user->id,
            'password' => 'nullable|min:8',
            'role' => 'required|in:admin,teacher,student',

            // student
            'student_code' => 'nullable|string|max:50|unique:students,student_code,'.optional($user->student)->id,
            'faculty' => 'nullable|string|max:100',
            'class_name' => 'nullable|string|max:100',

            // teacher
            'department' => 'nullable|string|max:100',
            'title' => 'nullable|string|max:100',
        ]);

        DB::transaction(function() use ($data, $user) {
            $user->update([
                'name' => $data['name'],
                'email' => $data['email'],
                'role' => $data['role'],
                // chỉ đổi pass khi nhập
                'password' => isset($data['password']) && $data['password'] ? bcrypt($data['password']) : $user->password,
            ]);

            // đồng bộ profile theo role
            if ($data['role'] === 'student') {
                // đảm bảo teacher profile (nếu có) dọn dẹp nhẹ
                if ($user->teacher) { $user->teacher()->delete(); }

                $user->student()
                    ->updateOrCreate(['user_id' => $user->id], [
                        'student_code' => $data['student_code'] ?? $user->student->student_code ?? null,
                        'faculty' => $data['faculty'] ?? null,
                        'class_name' => $data['class_name'] ?? null,
                    ]);
            } elseif ($data['role'] === 'teacher') {
                if ($user->student) { $user->student()->delete(); }

                $user->teacher()
                    ->updateOrCreate(['user_id' => $user->id], [
                        'department' => $data['department'] ?? null,
                        'title' => $data['title'] ?? null,
                    ]);
            } else {
                // admin: không cần profile con
                if ($user->student) { $user->student()->delete(); }
                if ($user->teacher) { $user->teacher()->delete(); }
            }
        });

        return redirect()->route('users.index')->with('ok','Cập nhật tài khoản thành công');
    }

    public function destroy(\App\Models\User $user)
    {
        DB::transaction(function() use ($user){
            // “deactivate” lành tính
            $user->update(['status' => 'inactive']);
            // tuỳ chính sách: có thể xoá profile mềm
            if ($user->student) { $user->student()->delete(); }
            if ($user->teacher) { $user->teacher()->delete(); }
        });
        return back()->with('ok','Đã vô hiệu hoá tài khoản');
    }
}
