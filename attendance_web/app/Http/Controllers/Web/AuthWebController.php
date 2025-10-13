<?php

namespace App\Http\Controllers\Web;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthWebController
{
    public function showLogin()
    {
        if (Auth::guard('web')->check() && Auth::guard('web')->user()->role === 'admin') {
            return redirect()->route('dashboard');
        }
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $cred = $request->validate([
            'email'    => ['required','email'],
            'password' => ['required','string'],
            'remember' => ['nullable','boolean'],
        ]);

        // Chỉ cho admin đăng nhập web
        $payload = [
            'email'    => $cred['email'],
            'password' => $cred['password'],
            'role'     => 'admin',       // ép role=admin
            // nếu có cột status, có thể thêm: 'status' => 'active'
        ];

        if (Auth::guard('web')->attempt($payload, $request->boolean('remember'))) {
            $request->session()->regenerate();
            return redirect()->route('dashboard');
        }

        // Không lộ thông tin role cho attacker
        return back()
            ->withErrors(['email' => 'Sai email hoặc mật khẩu'])
            ->onlyInput('email');
    }

    public function logout(Request $request)
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }
}
