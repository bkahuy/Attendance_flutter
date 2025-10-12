<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;


class AttendanceRecord extends Model
{
    public $timestamps = false; // dùng created_at từ DB default
    protected $fillable = ['attendance_session_id','student_id','status','photo_path','gps_lat','gps_lng','note','created_at'];


    public function session(): BelongsTo { return $this->belongsTo(AttendanceSession::class, 'attendance_session_id'); }
    public function student(): BelongsTo { return $this->belongsTo(Student::class); }
}
