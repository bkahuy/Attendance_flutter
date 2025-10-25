<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;


class ClassSection extends Model
{
    protected $fillable = ['course_id','teacher_id','major_id','term','room','capacity','start_date','end_date'];


    public function course(): BelongsTo { return $this->belongsTo(Course::class); }
    public function teacher(): BelongsTo { return $this->belongsTo(Teacher::class); }
    public function major(): BelongsTo { return $this->belongsTo(Major::class); }
    public function schedules(): HasMany { return $this->hasMany(Schedule::class); }
    public function sessions(): HasMany { return $this->hasMany(AttendanceSession::class); }
    public function students(): BelongsToMany { return $this->belongsToMany(Student::class, 'class_section_students'); }
    public function classes(): BelongsToMany { return $this->belongsToMany(StudentClass::class, 'class_section_classes'); }



}
