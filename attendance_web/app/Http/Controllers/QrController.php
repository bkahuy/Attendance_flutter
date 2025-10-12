<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\{AttendanceSession, QrToken};

class QrController extends Controller{
  public function resolve(Request $request){
    $request->validate(['token'=>'required|string']);
    $now=now();
    $qr = DB::table('qr_tokens')->where('token',$request->token)->where('expires_at','>',$now)->first();
    if(!$qr){ return response()->json(['error'=>'Invalid or expired token'],400); }
    $session = AttendanceSession::with('classSection.course')->find($qr->attendance_session_id);
    if(!$session || !in_array($session->status,['scheduled','active'])){
      return response()->json(['error'=>'Session not available'],400);
    }
    return response()->json([
      'session_id'=>$session->id,
      'class_section'=>[
        'id'=>$session->class_section_id,
        'course'=>$session->classSection?->course?->name,
        'term'=>$session->classSection?->term,
        'room'=>$session->classSection?->room,
      ],
      'start_at'=>$session->start_at,
      'end_at'=>$session->end_at,
      'mode_flags'=>$session->mode_flags,
      'requires_password'=>!empty($session->password_hash),
    ]);
  }
}
