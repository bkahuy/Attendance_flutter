<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;


class QrToken extends Model
{
    public $timestamps = false;
    protected $fillable = ['attendance_session_id','token','expires_at','created_at'];
    protected $casts = ['expires_at' => 'datetime','created_at'=>'datetime'];
    public function session(): BelongsTo { return $this->belongsTo(AttendanceSession::class, 'attendance_session_id'); }
}
