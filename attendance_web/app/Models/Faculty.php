<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Faculty extends Model
{
    protected $fillable = ['name'];

    // Khoa có nhiều ngành (nếu bạn đang dùng)
    public function majors(): HasMany
    {
        return $this->hasMany(Major::class);
    }

    // Khoa có nhiều sinh viên (qua khóa ngoại faculty_id trên students)
    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'faculty_id');
    }
}
