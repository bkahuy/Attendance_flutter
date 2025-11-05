<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;


class ClassSection extends Model
{
    protected $fillable = ['course_id','teacher_id','major_id','term','room','capacity','start_date','end_date'];


    public function course(): BelongsTo { return $this->belongsTo(Course::class, 'course_id'); }
    public function teacher(): BelongsTo { return $this->belongsTo(Teacher::class); }
    public function major(): BelongsTo { return $this->belongsTo(Major::class); }
    public function schedules(): HasMany { return $this->hasMany(Schedule::class); }
    public function sessions(): HasMany { return $this->hasMany(AttendanceSession::class); }
    public function students(): BelongsToMany { return $this->belongsToMany(Student::class); }
    public function classes()
    {
        // 🌟 SỬA LỖI Ở ĐÂY
        return $this->belongsToMany(
            StudentClass::class,           // 👈 Model của bảng 'classes' (bạn đặt tên là StudentClass)
            'class_section_classes', // 👈 Tên bảng lồng (pivot)
            'class_section_id',      // 👈 Khóa ngoại của model NÀY (ClassSection)
            'class_id'               // 👈 Khóa ngoại của model KIA (Class)
        );
    }



}
