<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Student extends Model
{

    protected $fillable = [
        'user_id','student_code','birthday','class_id',
        'faculty','class_name',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function studentClass(): BelongsTo
    {
        return $this->belongsTo(StudentClass::class, 'class_id');
    }

    public function classSections(): BelongsToMany
    {
        return $this->belongsToMany(ClassSection::class, 'class_section_students');
    }

    public function records(): HasMany
    {
        return $this->hasMany(AttendanceRecord::class);
    }

    public function getFacultyNameAttribute(): ?string
    {
        return $this->studentClass->major->faculty->name ?? ($this->faculty ?? null);
    }
}
