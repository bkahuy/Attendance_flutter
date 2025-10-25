<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;


class Course extends Model
{
    protected $fillable = ['code','name','credits','department_id'];
    public function department(): BelongsTo { return $this->belongsTo(Department::class); }
    public function classSections(): HasMany { return $this->hasMany(ClassSection::class); }
}
