<?php
//
//namespace App\Http\Controllers;
//
//use Illuminate\Http\Request;
//use Illuminate\Support\Facades\{DB,Storage,Hash};
//use Illuminate\Validation\Rule;
//use App\Models\{AttendanceSession, AttendanceRecord, QrToken};
//use App\Services\GeoService;
//
//class AttendanceController extends Controller{
//  public function createSession(Request $request){
//    $user=$request->user(); if($user->role!=='teacher'){ return response()->json(['error'=>'Forbidden'],403);}
//    $data=$request->validate([
//      'class_section_id'=>['required','integer','exists:class_sections,id'],
//      'start_at'=>['required','date_format:Y-m-d H:i:s'],
//      'end_at'=>['required','date_format:Y-m-d H:i:s','after:start_at'],
//      'mode_flags'=>['nullable','array'],
//      'password'=>['nullable','string','min:3'],
//      'schedule_id'=>['nullable','integer','exists:schedules,id'],
//    ]);
//    $session = \App\Models\AttendanceSession::create([
//      'class_section_id'=>$data['class_section_id'],
//      'schedule_id'=>$data['schedule_id']??null,
//      'created_by'=>$user->id,
//      'start_at'=>$data['start_at'],
//      'end_at'=>$data['end_at'],
//      'mode_flags'=>$data['mode_flags']??['camera'=>true,'qr'=>true],
//      'password_hash'=> !empty($data['password']) ? Hash::make($data['password']) : null,
//      'status'=>'active',
//    ]);
//    $qr=null; if(!empty($session->mode_flags['qr'])){ $token=bin2hex(random_bytes(16)); $qr=QrToken::create(['attendance_session_id'=>$session->id,'token'=>$token,'expires_at'=>now()->addMinutes(config('attendance.qr_expire_minutes'))]); }
//    return response()->json(['session'=>$session,'qr'=>$qr?['token'=>$qr->token,'expires_at'=>$qr->expires_at]:null],201);
//  }
//
//  public function sessionDetail($id){ $session=\App\Models\AttendanceSession::with('classSection.course')->findOrFail($id); return response()->json($session); }
//
//  public function checkIn(Request $request){
//    $user=$request->user(); if($user->role!=='student'){ return response()->json(['error'=>'Forbidden'],403);}
//    $data=$request->validate([
//      'attendance_session_id'=>['required','integer','exists:attendance_sessions,id'],
//      'status'=>['required', Rule::in(['present','late','absent'])],
//      'password'=>['nullable','string'],
//      'photo'=>['required','image','max:5120'],
//      'gps_lat'=>['nullable','numeric'],
//      'gps_lng'=>['nullable','numeric'],
//    ]);
//    $session=\App\Models\AttendanceSession::findOrFail($data['attendance_session_id']); $now=now();
//    if($now->lt($session->start_at) || $now->gt($session->end_at)){ return response()->json(['error'=>'Session closed or not started'],400);}
//    if(!empty($session->password_hash)){
//      if(empty($data['password']) || !Hash::check($data['password'],$session->password_hash)) return response()->json(['error'=>'Invalid password'],400);
//    }
//    $mode=$session->mode_flags ?? []; if(!empty($mode['gps'])){
//      $sch = $session->schedule; if(!$sch || is_null($sch->location_lat) || is_null($sch->location_lng)) return response()->json(['error'=>'GPS required but schedule has no location'],400);
//      if(empty($data['gps_lat']) || empty($data['gps_lng'])) return response()->json(['error'=>'GPS coordinates required'],400);
//      $dist=GeoService::distanceMeters((float)$sch->location_lat,(float)$sch->location_lng,(float)$data['gps_lat'],(float)$data['gps_lng']); $radius=(int)config('attendance.gps_radius_m',200);
//      if($dist>$radius) return response()->json(['error'=>'Out of location radius','distance_m'=>round($dist)],400);
//    }
//    $path=$request->file('photo')->store('attendances','public'); $url=Storage::disk('public')->url($path);
//    $student = $user->student; if(!$student) return response()->json(['error'=>'Student profile not found'],400);
//    \App\Models\AttendanceRecord::updateOrCreate(['attendance_session_id'=>$session->id,'student_id'=>$student->id],[ 'status'=>$data['status'],'photo_path'=>$url,'gps_lat'=>$data['gps_lat']??null,'gps_lng'=>$data['gps_lng']??null,'note'=>null ]);
//    return response()->json(['message'=>'Checked in','photo'=>$url]);
//  }
//}
