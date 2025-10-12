<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\Admin\UsersWebController;
use App\Http\Controllers\Web\Admin\CoursesWebController;
use App\Http\Controllers\Web\Admin\ClassSectionsWebController;
use App\Http\Controllers\Web\Admin\SchedulesWebController;

// Auth (session)
Route::get('/login', [AuthWebController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthWebController::class, 'login'])->name('login.post');
Route::post('/logout', [AuthWebController::class, 'logout'])->name('logout');

// Admin pages (session + role:admin)
Route::middleware(['web','auth','role:admin'])->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');

    Route::resource('users', UsersWebController::class)->except(['show']);
    Route::resource('courses', CoursesWebController::class)->except(['show']);
    Route::resource('class-sections', ClassSectionsWebController::class)->except(['show']);
    Route::post('schedules', [SchedulesWebController::class, 'store'])->name('schedules.store');
    Route::delete('schedules/{id}', [SchedulesWebController::class, 'destroy'])->name('schedules.destroy');
});
