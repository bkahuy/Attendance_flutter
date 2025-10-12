<?php


namespace App\Models;


use Illuminate\Foundation\Auth\User as Authenticatable;
use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;


class User extends Authenticatable implements JWTSubject
{
    protected $fillable = ['name','email','password','role','phone','status'];
    protected $hidden = ['password'];


    public function getJWTIdentifier(){ return $this->getKey(); }
    public function getJWTCustomClaims(): array
    { return []; }


    public function student(): HasOne { return $this->hasOne(Student::class); }
    public function teacher(): HasOne { return $this->hasOne(Teacher::class); }


    public function createdSessions(): HasMany { return $this->hasMany(AttendanceSession::class, 'created_by'); }
}
