<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;


class Course extends Model
{
    protected $fillable = ['code','name','credits'];
    public function classSections(): HasMany { return $this->hasMany(ClassSection::class); }
}
