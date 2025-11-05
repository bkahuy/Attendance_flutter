<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Admin\{
    DashboardController, UsersController, ClassSectionsController,
    SchedulesController, ReportsController
};
use App\Http\Controllers\Web\Admin\{
    StudentsWebController, TeachersWebController, CoursesWebController,
    ClassSectionsWebController
};
use App\Http\Controllers\Web\Admin\ClassSectionsWebController as CSWeb;
use App\Http\Controllers\Web\Admin\StudentClassesWebController;
use App\Http\Controllers\Web\Admin\SchedulesWebController;

// ==== Guest ====
Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthWebController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthWebController::class, 'login'])
        ->middleware('throttle:6,1')
        ->name('login.post');
});

// ==== Admin (web session + role:admin) ====
Route::middleware(['auth:web','role:admin'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    // --- Schedules: tách view/data ---
    Route::get('admin/schedules',               [SchedulesWebController::class, 'index'])->name('admin.schedules.index');
    Route::get('admin/schedules/create',        [SchedulesWebController::class, 'create'])->name('admin.schedules.create');
    Route::get('admin/schedules/{id}/edit',     [SchedulesWebController::class, 'edit'])->name('admin.schedules.edit');

    Route::post  ('admin/schedules',            [SchedulesWebController::class, 'store'])->name('admin.schedules.store');
    Route::put   ('admin/schedules/{id}',       [SchedulesWebController::class, 'update'])->name('admin.schedules.update');
    Route::delete('admin/schedules/{id}',       [SchedulesWebController::class, 'destroy'])->name('admin.schedules.destroy');


    // --- Reports ---
    Route::get('admin/reports/attendance', [ReportsController::class,'attendance'])->name('reports.attendance');
    Route::get('admin/reports/attendance/export', [ReportsController::class,'exportCsv'])->name('reports.attendance.export');

    // --- Users ---
    Route::resource('admin/users', UsersController::class)->names('admin.users');

    // =========================
    //   COURSES: chỉ 1 controller (Web)
    //   Tránh đè với Admin\CoursesController (đã bỏ hẳn)
    // =========================
    Route::get   ('admin/courses',            [CoursesWebController::class, 'index'])->name('admin.courses.index');
    Route::get   ('admin/courses/create',     [CoursesWebController::class, 'create'])->name('admin.courses.create');
    Route::post  ('admin/courses',            [CoursesWebController::class, 'store'])->name('admin.courses.store');
    Route::get   ('admin/courses/{id}/edit',  [CoursesWebController::class, 'edit'])->name('admin.courses.edit');
    Route::put   ('admin/courses/{id}',       [CoursesWebController::class, 'update'])->name('admin.courses.update');
    Route::delete('admin/courses/{id}',       [CoursesWebController::class, 'destroy'])->name('admin.courses.destroy');
    Route::get   ('admin/courses/{id}',       [CoursesWebController::class, 'show'])->name('admin.courses.show');

    // ==================================
    //   CLASS SECTIONS (tách view/data)
    // ==================================
    // Index / Create / Edit / Show
    Route::get   ('admin/class-sections',              [CSWeb::class, 'index'])->name('admin.class-sections.index');
    Route::get   ('admin/class-sections/create',       [CSWeb::class, 'create'])->name('admin.class-sections.create');
    Route::get   ('admin/class-sections/{class_section}/edit', [CSWeb::class, 'edit'])->name('admin.class-sections.edit');
    Route::get   ('admin/class-sections/{class_section}',      [CSWeb::class, 'show'])->name('admin.class-sections.show');

// Store / Update / Destroy  (đều trả redirect, KHÔNG JSON)
    Route::post  ('admin/class-sections',                    [CSWeb::class, 'store'])->name('admin.class-sections.store');
    Route::put   ('admin/class-sections/{class_section}',    [CSWeb::class, 'update'])->name('admin.class-sections.update');
    Route::delete('admin/class-sections/{class_section}',    [CSWeb::class, 'destroy'])->name('admin.class-sections.destroy');

// (giữ helpers nếu bạn đang dùng)
    Route::get ('admin/class-sections/{classSection}/students', [\App\Http\Controllers\Admin\ClassSectionsController::class, 'students'])->name('class-sections.students');
    Route::post('admin/class-sections/{classSection}/enroll-sync', [\App\Http\Controllers\Admin\ClassSectionsController::class, 'enrollSync'])->name('class-sections.enrollSync');



    // Enrollment helpers
    Route::get ('admin/class-sections/{classSection}/students', [ClassSectionsController::class, 'students'])->name('class-sections.students');
    Route::post('admin/class-sections/{classSection}/enroll-sync', [ClassSectionsController::class, 'enrollSync'])->name('class-sections.enrollSync');

    // Students / Teachers
    Route::resource('admin/students', StudentsWebController::class)->names('admin.students');
    Route::resource('admin/teachers', TeachersWebController::class)->names('admin.teachers');

    // LỚP CHÍNH KHOÁ (StudentClass)

    Route::get   ('admin/classes',             [StudentClassesWebController::class, 'index'])->name('admin.classes.index');
    Route::get   ('admin/classes/create',      [StudentClassesWebController::class, 'create'])->name('admin.classes.create');
    Route::post  ('admin/classes',             [StudentClassesWebController::class, 'store'])->name('admin.classes.store');
    Route::get   ('admin/classes/{id}/edit',   [StudentClassesWebController::class, 'edit'])->name('admin.classes.edit');
    Route::put   ('admin/classes/{id}',        [StudentClassesWebController::class, 'update'])->name('admin.classes.update');
    Route::delete('admin/classes/{id}',        [StudentClassesWebController::class, 'destroy'])->name('admin.classes.destroy');

});

// ==== Logout ====
Route::post('/logout', [AuthWebController::class, 'logout'])->middleware('auth:web')->name('logout');

// ==== Root redirect ====
Route::get('/', fn() => redirect()->route('dashboard'));
