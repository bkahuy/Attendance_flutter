<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{AuthController,TeacherController,StudentController,AttendanceController,QrController,StatsController};

// Auth (JWT cho Flutter)
Route::prefix('auth')->group(function(){
    Route::post('login',[AuthController::class,'login']);// GV/SV
    Route::middleware('auth:api')->get('profile',[AuthController::class,'profile']);
    Route::middleware('auth:api')->post('refresh',[AuthController::class,'refresh']);
    Route::middleware('auth:api')->post('logout',[AuthController::class,'logout']);
});

Route::post('change-password', [AuthController::class, 'changePassword']);

// Teacher-only APIs
Route::middleware(['auth:api','role:teacher'])->group(function(){
    Route::get('teacher/schedule',[TeacherController::class,'schedule']);
    Route::post('attendance/session',[TeacherController::class,'createSession']);
    Route::get('attendance/session/{id}',[TeacherController::class,'sessionDetail']);
    Route::get('stats/class/{id}',[StatsController::class,'classStats']);
    Route::get('stats/session/{id}',[StatsController::class,'sessionStats']);
});

// Student-only APIs
Route::middleware(['auth:api','role:student'])->group(function(){
    // Sửa lại cho đúng
    Route::get('/student/schedule', [StudentController::class, 'schedule']);
    Route::post('attendance/checkin',[StudentController::class,'checkIn']);
    Route::get('stats/student',[StatsController::class,'studentOverview']);
    Route::get('attendance/resolve-qr',[QrController::class,'resolve']);
    Route::get('/student/class-sections/{id}/attendance', [StudentController::class, 'attendanceHistory']);
});

//Nhan dien khuon mat
Route::middleware(['auth:api','role:student'])->group(function () {
    Route::post('face/enroll', [\App\Http\Controllers\FaceController::class, 'enroll']);
});
Route::middleware(['auth:api'])->group(function () {
    Route::post('face/match',  [\App\Http\Controllers\FaceController::class, 'logMatch']);
});

