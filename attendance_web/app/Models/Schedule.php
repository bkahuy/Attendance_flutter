<?php


namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;


class Schedule extends Model
{
    protected $fillable = ['class_section_id','date','weekday','start_time','end_time','recurring_flag','location_lat','location_lng','room'];
    protected $casts = [
        'date' => 'date',
        'start_time' => 'datetime:H:i:s',
        'end_time' => 'datetime:H:i:s',
        'recurring_flag' => 'boolean',
        'location_lat' => 'float',
        'location_lng' => 'float',

    ];
    public function classSection(): BelongsTo { return $this->belongsTo(ClassSection::class); }
}
