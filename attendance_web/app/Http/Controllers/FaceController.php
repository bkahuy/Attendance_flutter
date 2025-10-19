<?php

namespace App\Http\Controllers;

use App\Http\Requests\FaceEnrollRequest;
use App\Http\Requests\FaceMatchRequest;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;

class FaceController extends Controller
{
    // POST /api/face/enroll
    public function enroll(FaceEnrollRequest $r)
    {
        $user = $r->user();
        $student = $user->student ?? null;
        if (!$student) {
            return response()->json(['error' => 'Student profile not found'], 400);
        }

        $bin = base64_decode($r->input('template_base64'), true);
        if ($bin === false) {
            return response()->json(['error' => 'Invalid base64 for template'], 422);
        }

        $provider = $r->input('provider', 'regula');
        $id = DB::table('face_templates')->insertGetId([
            'student_id'    => $student->id,
            'provider'      => $provider,
            'template'      => $bin,
            'version'       => $r->input('version'),
            'quality_score' => $r->input('quality_score'),
            'is_primary'    => $r->boolean('is_primary', true),
            'created_at'    => Carbon::now(),
        ]);

        // Nếu template này là primary => bỏ primary ở template khác của cùng SV
        if ($r->boolean('is_primary', true)) {
            DB::table('face_templates')
                ->where('student_id', $student->id)
                ->where('id', '<>', $id)
                ->update(['is_primary' => 0]);
        }

        return response()->json([
            'face_template_id' => $id,
            'student_id'       => $student->id,
            'provider'         => $provider,
        ], 201);
    }

    // POST /api/face/match
    public function logMatch(FaceMatchRequest $r)
    {
        // Nếu client gửi spoof_flags là JSON string -> cố gắng parse
        $spoof = $r->input('spoof_flags');
        if (is_string($spoof)) {
            // đảm bảo string JSON hợp lệ; nếu không thì để null
            $spoof = json_decode($spoof, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                $spoof = null;
            }
        }

        $id = DB::table('face_matches')->insertGetId([
            'attendance_session_id' => $r->input('attendance_session_id'),
            'student_id'            => $r->input('student_id'),
            'face_template_id'      => $r->input('face_template_id'),
            'method'                => $r->input('method'),
            'similarity'            => $r->input('similarity'),
            'threshold'             => $r->input('threshold'),
            'decision'              => $r->input('decision'),
            'liveness_type'         => $r->input('liveness_type', 'none'),
            'liveness_score'        => $r->input('liveness_score'),
            'spoof_flags'           => $spoof ? json_encode($spoof) : null,
            'model_version'         => $r->input('model_version'),
            'image_path'            => $r->input('image_path'),
            'created_at'            => now(),
        ]);

        return response()->json(['face_match_id' => $id], 201);
    }
}
