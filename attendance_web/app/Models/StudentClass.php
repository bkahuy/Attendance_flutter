<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class StudentClass extends Model
{
    protected $fillable = ['name', 'major_id'];

    public function major(): BelongsTo
    {
        return $this->belongsTo(Major::class);
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'class_id');
    }

    public function classSections(): BelongsToMany
    {
        return $this->belongsToMany(ClassSection::class, 'class_section_classes', 'class_id', 'class_section_id')
            ->withPivot('assigned_at');
    }
}
