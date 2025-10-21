<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UsersController;
use App\Http\Controllers\Admin\CoursesController;
use App\Http\Controllers\Admin\ClassSectionsController;
use App\Http\Controllers\Admin\SchedulesController;
use App\Http\Controllers\Admin\ReportsController;

// Guest: chỉ trang login
Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthWebController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthWebController::class, 'login'])
        ->middleware('throttle:6,1')
        ->name('login.post');
});

// Admin-only area
Route::middleware(['auth:web','role:admin'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // Users
    Route::resource('admin/users', UsersController::class)
        ->names('admin.users');                 // admin.users.*

    // Courses / ClassSections / Schedules
    Route::resource('admin/courses', CoursesController::class)
        ->names('admin.courses');              // admin.courses.*
    Route::resource('admin/class-sections', ClassSectionsController::class)
        ->names('admin.class-sections');// admin.class-sections.*
    Route::resource('admin/schedules', SchedulesController::class)
        ->names('admin.schedules');         // admin.schedules.*

    // Reports
    Route::get('admin/reports/attendance', [ReportsController::class,'attendance'])
        ->name('reports.attendance');

    // Enrollment APIs
    Route::get('admin/class-sections/{classSection}/students',
        [ClassSectionsController::class, 'students']
    )->name('class-sections.students');

    Route::post('admin/class-sections/{classSection}/enroll-sync',
        [ClassSectionsController::class, 'enrollSync']
    )->name('class-sections.enrollSync');

    // Aliases để giữ tương thích sidebar/link cũ (tuỳ chọn)
    Route::get('admin/students', fn() => redirect()->route('admin.users.index', ['role' => 'student']))
        ->name('students.index');
    Route::get('admin/teachers', fn() => redirect()->route('admin.users.index', ['role' => 'teacher']))
        ->name('teachers.index');
    Route::get('admin/attendance', fn() => redirect()->route('reports.attendance'))
        ->name('attendance.index');
});



Route::post('/logout', [AuthWebController::class, 'logout'])
    ->middleware('auth:web')
    ->name('logout');

Route::get('/', fn() => redirect()->route('dashboard'));
