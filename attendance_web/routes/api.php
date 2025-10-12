<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\{AuthController,TeacherController,StudentController,AttendanceController,QrController,StatsController};
use App\Http\Controllers\FirebaseBridgeController;

// ==== Firebase custom token ====
Route::post('firebase/token/login', [FirebaseBridgeController::class, 'loginAndIssueToken']);
Route::middleware('auth:api')->post('firebase/token', [FirebaseBridgeController::class, 'issueTokenForCurrent']);

Route::prefix('auth')->group(function(){
  Route::post('login',[AuthController::class,'login']);
  Route::middleware('auth:api')->get('profile',[AuthController::class,'profile']);
  Route::middleware('auth:api')->post('logout',[AuthController::class,'logout']);
});

Route::middleware(['auth:api'])->group(function(){
  Route::middleware('role:teacher')->group(function(){
    Route::get('teacher/schedule',[TeacherController::class,'scheduleByDate']);
    Route::post('attendance/session',[AttendanceController::class,'createSession']);
    Route::get('attendance/session/{id}',[AttendanceController::class,'sessionDetail']);
    Route::get('stats/class/{id}',[StatsController::class,'classStats']);
    Route::get('stats/session/{id}',[StatsController::class,'sessionStats']);
  });
  Route::middleware('role:student')->group(function(){
    Route::get('student/schedule',[StudentController::class,'scheduleByDate']);
    Route::post('attendance/checkin',[AttendanceController::class,'checkIn']);
    Route::get('stats/student',[StatsController::class,'studentOverview']);
    Route::get('attendance/resolve-qr',[QrController::class,'resolve']);
  });
});
