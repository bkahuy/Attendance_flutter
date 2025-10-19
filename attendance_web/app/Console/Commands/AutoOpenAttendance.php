<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\{Schedule, AttendanceSession, ClassSection};
use Carbon\Carbon;

class AutoOpenAttendance extends Command{
  protected $signature='attendance:auto-open';
  protected $description='Auto create attendance sessions based on schedules when time comes';
  public function handle(): int{
    $now=Carbon::now(); $weekday=$now->dayOfWeek; $created=0;
    $recur = Schedule::where('recurring_flag',1)->where('weekday',$weekday)->get();
    foreach($recur as $sch){
      $start = Carbon::parse($now->format('Y-m-d').' '.$sch->start_time);
      $end   = Carbon::parse($now->format('Y-m-d').' '.$sch->end_time);
      if (abs($now->diffInMinutes($start,false))>2) continue;
      $exists = AttendanceSession::where('class_section_id',$sch->class_section_id)
        ->whereBetween('start_at', [$start->copy()->subMinutes(1), $start->copy()->addMinutes(1)])
        ->exists();
      if(!$exists){ AttendanceSession::create([
        'class_section_id'=>$sch->class_section_id,
        'schedule_id'=>$sch->id,
        'created_by'=>ClassSection::find($sch->class_section_id)?->teacher?->user_id ?? 1,
        'start_at'=>$start,
        'end_at'=>$end,
        'mode_flags'=>['camera'=>true],
        'status'=>'active',
      ]); $created++; }
    }
    $one = Schedule::where('recurring_flag',0)->whereDate('date',$now->toDateString())->get();
    foreach($one as $sch){
      $start = Carbon::parse($sch->date.' '.$sch->start_time); $end = Carbon::parse($sch->date.' '.$sch->end_time);
      if (abs($now->diffInMinutes($start,false))>2) continue;
      $exists = AttendanceSession::where('class_section_id',$sch->class_section_id)
        ->whereBetween('start_at', [$start->copy()->subMinutes(1), $start->copy()->addMinutes(1)])
        ->exists();
      if(!$exists){ AttendanceSession::create([
        'class_section_id'=>$sch->class_section_id,
        'schedule_id'=>$sch->id,
        'created_by'=>ClassSection::find($sch->class_section_id)?->teacher?->user_id ?? 1,
        'start_at'=>$start,'end_at'=>$end,'mode_flags'=>['camera'=>true],'status'=>'active',
      ]); $created++; }
    }
    $this->info('Created '.$created.' sessions.');
    return self::SUCCESS;
  }
}
