<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;


class UsersController extends Controller
{
    public function index() { return User::paginate(20); }


    public function store(Request $req)
    {
        $data = $req->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'role' => 'required|in:admin,teacher,student',
            'password' => 'nullable|min:6',
        ]);
        $data['password'] = Hash::make($data['password'] ?? '123456');
        $user = User::create($data);
        return response()->json($user, 201);
    }


    public function show($id) { return User::findOrFail($id); }


    public function update(Request $req, $id)
    {
        $user = User::findOrFail($id);
        $data = $req->only('name','email','role','phone','status');
        if ($req->filled('password')) $data['password'] = Hash::make($req->password);
        $user->update($data);
        return response()->json($user);
    }


    public function destroy($id)
    {
        User::destroy($id);
        return response()->json(['message' => 'Deleted']);
    }
}
