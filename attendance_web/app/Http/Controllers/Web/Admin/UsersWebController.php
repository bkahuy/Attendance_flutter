<?php
namespace App\Http\Controllers\Web\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UsersWebController extends Controller
{
    public function index()
    {
        $q = request('q');
        $users = User::when($q, fn($qr)=>$qr->where('name','like',"%$q%")
            ->orWhere('email','like',"%$q%"))->orderByDesc('id')->paginate(12);
        return view('admin.users.index', compact('users','q'));
    }

    public function create() { return view('admin.users.create'); }

    public function store(Request $r)
    {
        $data = $r->validate([
            'name'=>'required',
            'email'=>'required|email|unique:users',
            'role'=>'required|in:admin,teacher,student',
            'password'=>'nullable|min:6',
            'phone'=>'nullable',
            'status'=>'nullable|in:active,inactive,blocked'
        ]);
        $data['password'] = Hash::make($data['password'] ?? '123456');
        User::create($data);
        return redirect()->route('users.index')->with('ok','Tạo tài khoản thành công');
    }

    public function edit($id)
    {
        $user = User::findOrFail($id);
        return view('admin.users.edit', compact('user'));
    }

    public function update(Request $r, $id)
    {
        $user = User::findOrFail($id);
        $data = $r->validate([
            'name'=>'required',
            'email'=>"required|email|unique:users,email,$id",
            'role'=>'required|in:admin,teacher,student',
            'password'=>'nullable|min:6',
            'phone'=>'nullable',
            'status'=>'nullable|in:active,inactive,blocked'
        ]);
        if (!empty($data['password'])) $data['password'] = Hash::make($data['password']);
        else unset($data['password']);
        $user->update($data);
        return redirect()->route('users.index')->with('ok','Cập nhật thành công');
    }

    public function destroy($id)
    {
        User::destroy($id);
        return back()->with('ok','Đã xoá');
    }
}
