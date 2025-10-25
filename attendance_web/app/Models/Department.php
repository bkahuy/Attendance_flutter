<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Department extends Model
{
    protected $fillable = ['name'];

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
}
