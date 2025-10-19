<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{AuthController,TeacherController,StudentController,AttendanceController,QrController,StatsController};

// Auth (JWT cho Flutter)
Route::prefix('auth')->group(function(){
    Route::post('login',[AuthController::class,'login']);            // GV/SV
    Route::middleware('auth:api')->get('profile',[AuthController::class,'profile']);
    Route::middleware('auth:api')->post('refresh',[AuthController::class,'refresh']);
    Route::middleware('auth:api')->post('logout',[AuthController::class,'logout']);
});

// Teacher-only APIs
Route::middleware(['auth:api','role:teacher'])->group(function(){
    Route::get('teacher/schedule',[TeacherController::class,'schedule']);
    Route::post('attendance/session',[AttendanceController::class,'createSession']);
    Route::get('attendance/session/{id}',[AttendanceController::class,'sessionDetail']);
    Route::get('stats/class/{id}',[StatsController::class,'classStats']);
    Route::get('stats/session/{id}',[StatsController::class,'sessionStats']);

});

// Student-only APIs
Route::middleware(['auth:api','role:student'])->group(function(){
    // Sửa 'scheduleByDate' thành 'schedule'
    Route::get('/student/schedule', [StudentController::class, 'schedule']);
    Route::post('attendance/checkin',[AttendanceController::class,'checkIn']);
    Route::get('stats/student',[StatsController::class,'studentOverview']);
    Route::get('attendance/resolve-qr',[QrController::class,'resolve']);
    Route::get('/student/class-sections/{id}/attendance', [StudentController::class, 'attendanceHistory']);
});
