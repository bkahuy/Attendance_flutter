<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{AuthController,TeacherController,StudentController,AttendanceController,QrController,StatsController};
use App\Http\Controllers\FaceController;

// Auth (JWT cho Flutter)
Route::prefix('auth')->group(function(){
    Route::post('login',[AuthController::class,'login']);// GV/SV
    Route::middleware('auth:api')->get('profile',[AuthController::class,'profile']);
    Route::middleware('auth:api')->post('refresh',[AuthController::class,'refresh']);
    Route::middleware('auth:api')->post('logout',[AuthController::class,'logout']);
    Route::post('change-password', [AuthController::class, 'changePassword']);
});

Route::middleware('auth:api')->group(function () {
    Route::post('/face/enroll', [FaceController::class, 'enroll']);
    Route::post('/face/verify', [FaceController::class, 'verify']);
});



// Teacher-only APIs
Route::middleware(['auth:api','role:teacher'])->group(function(){
    Route::get('teacher/schedule',[TeacherController::class,'schedule']);
    Route::post('attendance/session',[TeacherController::class,'createSession']);
    Route::put('attendance/session/{id}/close',[TeacherController::class,'closeSession']);
    Route::get('attendance/session/search',[TeacherController::class,'searchAttendanceHistory']);
    Route::get('attendance/sessionDetail/{id}/detail',[TeacherController::class,'sessionDetail']);
    Route::get('attendance/sessionDetail/{id}', [TeacherController::class, 'showSessionDetail']);
    Route::get('attendance/checkActiveSession/{id}',[TeacherController::class,'getActiveSessionByClass']);
    Route::get('stats/class/{id}',[StatsController::class,'classStats']);
    Route::get('stats/session/{id}',[StatsController::class,'sessionStats']);
});

// Student-only APIs['error' => 'SERVER_ERROR', 'hint' => $e->getMessage()], 500);
Route::middleware(['auth:api','role:student'])->group(function(){
    Route::get('/student/schedule', [StudentController::class, 'schedule']);
    Route::post('attendance/checkin',[StudentController::class,'checkIn']);
    Route::get('stats/student',[StatsController::class,'studentOverview']);
    Route::get('attendance/resolve-qr',[QrController::class,'resolve']);
    Route::get('/student/class-sections/{id}/attendance', [StudentController::class, 'attendanceHistory']);
});

//Nhan dien khuon mat
Route::middleware(['auth:api','role:student'])->group(function () {
    // 🎨 BƯỚC 2: Sửa 'face/enroll' thành 'student/register-face'
    Route::post('student/register-face', [FaceController::class, 'enroll']);
    Route::post('face/enroll', [\App\Http\Controllers\FaceController::class, 'enroll']);
});
Route::middleware(['auth:api'])->group(function () {
    Route::post('face/match',  [FaceController::class, 'logMatch']);
    Route::post('face/match',  [\App\Http\Controllers\FaceController::class, 'logMatch']);
});
