<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;


class AttendanceSession extends Model
{
    protected $fillable = ['class_section_id','schedule_id','created_by','start_at','end_at','mode_flags','password_hash','status'];
    protected $casts = [
        'start_at' => 'datetime',
        'end_at' => 'datetime',
        'mode_flags' => 'array',
    ];


    public function classSection(): BelongsTo { return $this->belongsTo(ClassSection::class, 'class_section_id'); }
    public function schedule(): BelongsTo { return $this->belongsTo(Schedule::class, 'schedule_id'); }
    public function creator(): BelongsTo { return $this->belongsTo(User::class, 'created_by'); }
    public function records(): HasMany { return $this->hasMany(AttendanceRecord::class); }

    public function qrTokens(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(\App\Models\QrToken::class, 'attendance_session_id');
    }
}
