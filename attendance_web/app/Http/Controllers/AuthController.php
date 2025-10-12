<?php


namespace App\Http\Controllers;


use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Facades\JWTAuth;


class AuthController extends Controller
{
    public function login(Request $request){
        try {
            $data = $request->validate([
                'email' => 'required|email',
                'password' => 'required',
            ]);
            if (!$token = auth('api')->attempt($data)) {
                return response()->json(['error' => 'Invalid credentials'], 401);
            }
            return response()->json(['token'=>$token, 'user'=>auth('api')->user()]);
        } catch (\Throwable $e) {
            \Log::error('Login error: '.$e->getMessage(), ['trace'=>$e->getTraceAsString()]);
            return response()->json(['error'=>'Server error','hint'=>$e->getMessage()], 500);
        }
    }




    public function refresh()
    {
        return response()->json(['token' => auth('api')->refresh()]);
    }


    public function profile()
    {
        return response()->json(auth('api')->user());
    }


    public function changePassword(Request $request)
    {
        $request->validate([
            'old_password' => 'required',
            'new_password' => 'required|min:6',
        ]);


        $user = auth('api')->user();
        if (!Hash::check($request->old_password, $user->password)) {
            return response()->json(['error' => 'Wrong old password'], 400);
        }
        $user->password = Hash::make($request->new_password);
        $user->save();
        return response()->json(['message' => 'Password updated']);
    }
}
