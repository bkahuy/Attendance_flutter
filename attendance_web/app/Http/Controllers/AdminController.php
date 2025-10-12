<?php
namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminController extends Controller
{
    public function index() { return User::paginate(20); }

    public function store(Request $req)
    {
        $req->validate([
            'name'=>'required','email'=>'required|email|unique:users','role'=>'required'
        ]);
        $user = User::create([
            'name'=>$req->name,
            'email'=>$req->email,
            'password'=>Hash::make($req->password ?? '123456'),
            'role'=>$req->role
        ]);
        return response()->json($user);
    }

    public function update(Request $req, $id)
    {
        $user = User::findOrFail($id);
        $user->update($req->all());
        return response()->json(['message'=>'Updated','user'=>$user]);
    }

    public function destroy($id)
    {
        User::destroy($id);
        return response()->json(['message'=>'Deleted']);
    }
}
