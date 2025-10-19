<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;


class Student extends Model
{
    protected $fillable = ['user_id','student_code','faculty','class_name','extra_info'];
    protected $casts = ['extra_info' => 'array'];


    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function classes(): BelongsToMany { return $this->belongsToMany(ClassSection::class, 'class_section_students'); }
    public function records(): HasMany { return $this->hasMany(AttendanceRecord::class); }

    public function classSections()
    {
        return $this->belongsToMany(\App\Models\ClassSection::class, 'class_section_students', 'student_id', 'class_section_id')
            ->withPivot('enrolled_at');
    }

}
