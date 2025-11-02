<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Web\AuthWebController;
use App\Http\Controllers\Admin\{
    DashboardController, UsersController, CoursesController, ClassSectionsController,
    SchedulesController, ReportsController
};
use App\Http\Controllers\Web\Admin\{
    StudentsWebController, TeachersWebController, CoursesWebController,
    ClassSectionsWebController, SchedulesWebController
};

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

    // --- Schedules: TÁCH RÕ ---
    Route::get('admin/schedules', [SchedulesWebController::class, 'index'])
        ->name('admin.schedules.index');
    Route::get('admin/schedules/create', [\App\Http\Controllers\Web\Admin\SchedulesWebController::class, 'create'])
        ->name('admin.schedules.create');
    Route::get('admin/schedules/{id}/edit', [\App\Http\Controllers\Web\Admin\SchedulesWebController::class, 'edit'])
        ->name('admin.schedules.edit');
    Route::resource('admin/schedules', \App\Http\Controllers\Admin\SchedulesController::class)
        ->only(['store','update','destroy'])->names([
            'store'   => 'admin.schedules.store',
            'update'  => 'admin.schedules.update',
            'destroy' => 'admin.schedules.destroy',
        ]);

    // --- Reports ---
    Route::get('admin/reports/attendance', [ReportsController::class,'attendance'])->name('reports.attendance');
    Route::get('admin/reports/attendance/export', [ReportsController::class,'exportCsv'])->name('reports.attendance.export');

    // --- Users ---
    Route::resource('admin/users', UsersController::class)->names('admin.users');

    // =========================
    //   COURSES (tách View/Data)
    // =========================
    // View (Blade): index/create/edit/show
    Route::resource('admin/courses', CoursesWebController::class)->only(['index','create','edit','show'])->names([
        'index'  => 'admin.courses.index',
        'create' => 'admin.courses.create',
        'edit'   => 'admin.courses.edit',
        'show'   => 'admin.courses.show',
    ]);
    // Data: store/update/destroy
    Route::resource('admin/courses', CoursesController::class)->only(['store','update','destroy'])->names([
        'store'   => 'admin.courses.store',
        'update'  => 'admin.courses.update',
        'destroy' => 'admin.courses.destroy',
    ]);

    // ==================================
    //   CLASS SECTIONS (tách View/Data)
    // ==================================
    Route::resource('admin/class-sections', ClassSectionsWebController::class)->only(['index','create','edit','show'])->names([
        'index'  => 'admin.class-sections.index',
        'create' => 'admin.class-sections.create',
        'edit'   => 'admin.class-sections.edit',
        'show'   => 'admin.class-sections.show',
    ]);
    Route::resource('admin/class-sections', ClassSectionsController::class)->only(['store','update','destroy'])->names([
        'store'   => 'admin.class-sections.store',
        'update'  => 'admin.class-sections.update',
        'destroy' => 'admin.class-sections.destroy',
    ]);

    // Enrollment helpers (giữ đường cũ)
    Route::get('admin/class-sections/{classSection}/students', [ClassSectionsController::class, 'students'])->name('class-sections.students');
    Route::post('admin/class-sections/{classSection}/enroll-sync', [ClassSectionsController::class, 'enrollSync'])->name('class-sections.enrollSync');

    // Students/Teachers (Web)
    Route::resource('admin/students', StudentsWebController::class)->names('admin.students');
    Route::resource('admin/teachers', TeachersWebController::class)->names('admin.teachers');
});

// ==== Logout ====
Route::post('/logout', [AuthWebController::class, 'logout'])->middleware('auth:web')->name('logout');

// ==== Root redirect ====
Route::get('/', fn() => redirect()->route('dashboard'));
