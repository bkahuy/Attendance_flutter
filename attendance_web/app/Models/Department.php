<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOneThrough;

class Department extends Model
{
    protected $fillable = ['name','faculty_id']; // giữ cũng không sao, miễn migration không bắt buộc cột này

    public function majors(): HasMany
    {
        return $this->hasMany(Major::class);
    }

    public function teachers(): HasMany
    {
        return $this->hasMany(Teacher::class);
    }

    public function courses(): HasMany
    {
        return $this->hasMany(Course::class);
    }

    /** Khoa của bộ môn: đi qua bảng majors (department_id -> majors.faculty_id -> faculties.id) */
    public function faculty(): HasOneThrough
    {
        return $this->hasOneThrough(
            Faculty::class,  // model đích
            Major::class,    // model trung gian
            'department_id', // FK ở majors trỏ về departments
            'id',            // PK ở faculties
            'id',            // PK ở departments
            'faculty_id'     // FK ở majors trỏ về faculties
        );
    }
}
