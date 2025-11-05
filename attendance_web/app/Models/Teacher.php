<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Teacher extends Model
{
    // Nếu bảng teachers KHÔNG có created_at/updated_at thì để false; có thì bỏ dòng dưới
    public $timestamps = false;

    protected $fillable = ['user_id','teacher_code','department_id'];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function department(): BelongsTo { return $this->belongsTo(Department::class); }
    public function classSections(): HasMany { return $this->hasMany(ClassSection::class, 'teacher_id'); }

    /** Tên khoa (đọc qua department->faculty) */
    public function getFacultyNameAttribute(): string
    {
        return $this->department->faculty->name ?? '';
    }
}
