<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;


class Teacher extends Model
{
    protected $fillable = ['user_id','teacher_code','dept'];


    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function classes(): HasMany { return $this->hasMany(ClassSection::class, 'teacher_id'); }
}
