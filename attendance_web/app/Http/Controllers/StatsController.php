<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\{AttendanceSession, AttendanceRecord, ClassSection, Student};

class StatsController extends Controller{
  public function classStats($classSectionId){
    $class = ClassSection::with('course')->findOrFail($classSectionId);
    $sessions = AttendanceSession::where('class_section_id',$classSectionId)->count();
    $agg = DB::table('attendance_records')->select('status', DB::raw('COUNT(*) as cnt'))
      ->whereIn('attendance_session_id', function($q) use($classSectionId){ $q->select('id')->from('attendance_sessions')->where('class_section_id',$classSectionId); })
      ->groupBy('status')->get()->keyBy('status');
    $byStudent = DB::table('attendance_records as ar')
      ->join('students as s','s.id','=','ar.student_id')
      ->join('users as u','u.id','=','s.user_id')
      ->select('u.name as student','s.id as student_id',
        DB::raw('SUM(CASE WHEN ar.status="present" THEN 1 ELSE 0 END) as present'),
        DB::raw('SUM(CASE WHEN ar.status="late" THEN 1 ELSE 0 END) as late'),
        DB::raw('SUM(CASE WHEN ar.status="absent" THEN 1 ELSE 0 END) as absent'))
      ->whereIn('ar.attendance_session_id', function($q) use($classSectionId){ $q->select('id')->from('attendance_sessions')->where('class_section_id',$classSectionId); })
      ->groupBy('s.id','u.name')->orderBy('u.name')->get();
    return response()->json([
      'class_section'=>['id'=>$class->id,'course'=>$class->course?->name,'term'=>$class->term,'room'=>$class->room],
      'total_sessions'=>$sessions,
      'totals'=>['present'=>(int)($agg['present']->cnt??0),'late'=>(int)($agg['late']->cnt??0),'absent'=>(int)($agg['absent']->cnt??0)],
      'by_student'=>$byStudent,
    ]);
  }

  public function sessionStats($sessionId){
    $session = AttendanceSession::with('classSection.course')->findOrFail($sessionId);
    $records = DB::table('attendance_records as ar')
      ->join('students as s','s.id','=','ar.student_id')
      ->join('users as u','u.id','=','s.user_id')
      ->select('u.name as student','ar.status','ar.photo_path','ar.gps_lat','ar.gps_lng','ar.created_at')
      ->where('ar.attendance_session_id',$sessionId)->orderBy('u.name')->get();
    $agg = DB::table('attendance_records')->select('status', DB::raw('COUNT(*) as cnt'))
      ->where('attendance_session_id',$sessionId)->groupBy('status')->get()->keyBy('status');
    return response()->json([
      'session'=>['id'=>$session->id,'class_section_id'=>$session->class_section_id,'course'=>$session->classSection?->course?->name,'term'=>$session->classSection?->term,'start_at'=>$session->start_at,'end_at'=>$session->end_at],
      'totals'=>['present'=>(int)($agg['present']->cnt??0),'late'=>(int)($agg['late']->cnt??0),'absent'=>(int)($agg['absent']->cnt??0)],
      'records'=>$records,
    ]);
  }

  public function studentOverview(Request $request){
    $user = $request->user();
    $student = Student::where('user_id',$user->id)->firstOrFail();
    $perClass = DB::table('class_sections as cs')
      ->join('courses as c','c.id','=','cs.course_id')
      ->leftJoin('attendance_sessions as s','s.class_section_id','=','cs.id')
      ->leftJoin('attendance_records as ar', function($join) use($student){ $join->on('ar.attendance_session_id','=','s.id')->where('ar.student_id','=',$student->id); })
      ->select('cs.id as class_section_id','c.name as course','cs.term',
        DB::raw('COUNT(DISTINCT s.id) as total_sessions'),
        DB::raw('SUM(CASE WHEN ar.status IS NOT NULL THEN 1 ELSE 0 END) as attended'),
        DB::raw('SUM(CASE WHEN ar.status="present" THEN 1 ELSE 0 END) as present'),
        DB::raw('SUM(CASE WHEN ar.status="late" THEN 1 ELSE 0 END) as late'),
        DB::raw('SUM(CASE WHEN ar.status="absent" THEN 1 ELSE 0 END) as absent'))
      ->whereIn('cs.id', function($q) use($student){ $q->select('class_section_id')->from('class_section_students')->where('student_id',$student->id); })
      ->groupBy('cs.id','c.name','cs.term')->orderBy('c.name')->get();
    return response()->json($perClass);
  }
}
