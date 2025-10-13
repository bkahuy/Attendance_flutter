<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Admin\DashboardController;

// Guest: chỉ trang login
Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthWebController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthWebController::class, 'login'])
        ->middleware('throttle:6,1')
        ->name('login.post');
});

// Admin-only area
Route::middleware(['auth:web', 'role:admin'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    // các route quản trị khác...
});

Route::post('/logout', [AuthWebController::class, 'logout'])
    ->middleware('auth:web')
    ->name('logout');

Route::get('/', fn() => redirect()->route('dashboard'));
