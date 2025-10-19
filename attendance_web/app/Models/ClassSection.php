<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;


class ClassSection extends Model
{
    protected $fillable = ['course_id','teacher_id','term','room','capacity','start_date','end_date'];


    public function course(): BelongsTo { return $this->belongsTo(Course::class); }
    public function teacher(): BelongsTo { return $this->belongsTo(Teacher::class); }
    public function schedules(): HasMany { return $this->hasMany(Schedule::class); }
    public function sessions(): HasMany { return $this->hasMany(AttendanceSession::class); }
    public function classSections()
    {
        return $this->belongsToMany(\App\Models\ClassSection::class, 'class_section_students', 'student_id', 'class_section_id')
            ->withPivot('enrolled_at');
    }



}
