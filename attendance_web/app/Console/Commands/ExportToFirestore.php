<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Kreait\Firebase\Factory;
use Google\Cloud\Firestore\FirestoreClient;

class ExportToFirestore extends Command
{
    protected $signature = 'export:firestore
        {--chunk=500 : Số record mỗi lần đọc MySQL}
        {--dry : Dry-run, chỉ log, không ghi Firestore}
        {--from=0 : Bắt đầu từ ID (để resume)}';

    protected $description = 'Export dữ liệu MySQL sang Cloud Firestore (mapping cho Attendance App)';

    /** @var FirestoreClient|null */
    protected $fs;

    protected $dry = false;

    public function handle(): int
    {
        $this->dry = (bool)$this->option('dry');

        // Init Firestore
        $factory = (new Factory())->withServiceAccount(config('services.firebase.credentials'));
        if (config('services.firebase.project_id')) {
            $factory = $factory->withProjectId(config('services.firebase.project_id'));
        }
        $this->fs = $factory->createFirestore()->database();

        $this->info('=== EXPORT START === Dry='.($this->dry?'YES':'NO'));

        DB::connection()->getPdo(); // confirm DB ok

        $this->exportUsers();
        $this->exportClassSectionsAndSchedules();
        $this->exportSessions();
        $this->exportAttendanceRecords();

        $this->info('=== EXPORT DONE ===');
        return self::SUCCESS;
    }

    /** Map users -> /users/{uid} */
    protected function exportUsers(): void
    {
        $this->section('Users -> /users/{uid}');
        $chunk = (int)$this->option('chunk');
        $from  = (int)$this->option('from');

        DB::table('users')
            ->where('id', '>=', $from)
            ->orderBy('id')
            ->chunk($chunk, function ($rows) {
                $batch = $this->fs->batch();
                $n = 0;

                foreach ($rows as $u) {
                    $uid = 'laravel-'.$u->id;
                    $docRef = $this->fs->collection('users')->document($uid);
                    $data = [
                        'uid'   => $uid,
                        'name'  => $u->name,
                        'email' => $u->email,
                        'role'  => $u->role,
                        'status'=> $u->status,
                        'created_at' => $this->ts($u->created_at),
                        'updated_at' => $this->ts($u->updated_at),
                    ];
                    if ($this->dry) {
                        $this->line("DRY users/$uid => ".json_encode($data));
                    } else {
                        $batch->set($docRef, $data, ['merge' => true]);
                        $n++;
                        if ($n >= 450) { // buffer
                            $batch->commit();
                            $batch = $this->fs->batch();
                            $n = 0;
                        }
                    }
                }
                if (!$this->dry) $batch->commit();
            });

        $this->ok();
    }

    /** Map class_sections + schedules */
    protected function exportClassSectionsAndSchedules(): void
    {
        $this->section('ClassSections -> /classSections/{id} + /schedules subcollection');
        $chunk = (int)$this->option('chunk');
        $from  = (int)$this->option('from');

        DB::table('class_sections')
            ->where('id', '>=', $from)
            ->orderBy('id')
            ->chunk($chunk, function ($rows) {
                foreach ($rows as $cs) {
                    $course = DB::table('courses')->where('id',$cs->course_id)->first();
                    $teacher = DB::table('teachers')->where('id',$cs->teacher_id)->first();
                    $teacherUserId = $teacher?->user_id;
                    $teacherUid = $teacherUserId ? 'laravel-'.$teacherUserId : null;

                    $csData = [
                        'id'     => (int)$cs->id,
                        'course' => $course?->name ?? null,
                        'course_code' => $course?->code ?? null,
                        'term'  => $cs->term,
                        'room'  => $cs->room,
                        'capacity' => $cs->capacity,
                        'start_date' => $this->date($cs->start_date),
                        'end_date'   => $this->date($cs->end_date),
                        'teacherUid' => $teacherUid,
                        'created_at' => $this->ts($cs->created_at),
                        'updated_at' => $this->ts($cs->updated_at),
                    ];

                    $docRef = $this->fs->collection('classSections')->document((string)$cs->id);

                    if ($this->dry) {
                        $this->line("DRY classSections/{$cs->id} => ".json_encode($csData));
                    } else {
                        $docRef->set($csData, ['merge' => true]);
                    }

                    // students in class_section_students -> embed array (optional)
                    $stuIds = DB::table('class_section_students')->where('class_section_id',$cs->id)->pluck('student_id')->all();
                    if ($stuIds) {
                        $uids = [];
                        foreach ($stuIds as $sid) {
                            $uid = DB::table('students')->where('id',$sid)->value('user_id');
                            if ($uid) $uids[] = 'laravel-'.$uid;
                        }
                        if (!$this->dry) $docRef->set(['studentUids'=>$uids], ['merge'=>true]);
                        else $this->line("DRY classSections/{$cs->id}.studentUids => ".json_encode($uids));
                    }

                    // schedules subcollection
                    $schedules = DB::table('schedules')->where('class_section_id',$cs->id)->get();
                    foreach ($schedules as $s) {
                        $sid = (string)$s->id;
                        $sData = [
                            'id' => (int)$s->id,
                            'recurring_flag' => (bool)$s->recurring_flag,
                            'weekday'        => is_null($s->weekday) ? null : (int)$s->weekday,
                            'date'           => $this->date($s->date),
                            'start_time'     => (string)$s->start_time,
                            'end_time'       => (string)$s->end_time,
                            'location_lat'   => is_null($s->location_lat) ? null : (float)$s->location_lat,
                            'location_lng'   => is_null($s->location_lng) ? null : (float)$s->location_lng,
                            'created_at'     => $this->ts($s->created_at),
                            'updated_at'     => $this->ts($s->updated_at),
                        ];
                        $sub = $docRef->collection('schedules')->document($sid);
                        if ($this->dry) $this->line("DRY classSections/{$cs->id}/schedules/$sid => ".json_encode($sData));
                        else $sub->set($sData, ['merge'=>true]);
                    }
                }
            });

        $this->ok();
    }

    /** Map attendance_sessions -> /sessions/{id} */
    protected function exportSessions(): void
    {
        $this->section('Sessions -> /sessions/{id}');
        $chunk = (int)$this->option('chunk');
        $from  = (int)$this->option('from');

        DB::table('attendance_sessions')
            ->where('id', '>=', $from)
            ->orderBy('id')
            ->chunk($chunk, function ($rows) {
                $batch = $this->fs->batch();
                $n = 0;

                foreach ($rows as $s) {
                    $class = DB::table('class_sections')->where('id',$s->class_section_id)->first();
                    $courseName = $class ? DB::table('courses')->where('id',$class->course_id)->value('name') : null;

                    $data = [
                        'id' => (int)$s->id,
                        'classSectionId' => (int)$s->class_section_id,
                        'course' => $courseName,
                        'start_at' => $this->dt($s->start_at),
                        'end_at'   => $this->dt($s->end_at),
                        'status'   => $s->status,
                        'mode_flags' => $this->json($s->mode_flags),
                        'created_by_uid' => $s->created_by ? ('laravel-'.$s->created_by) : null,
                        'created_at' => $this->ts($s->created_at),
                        'updated_at' => $this->ts($s->updated_at),
                    ];
                    $doc = $this->fs->collection('sessions')->document((string)$s->id);
                    if ($this->dry) $this->line("DRY sessions/{$s->id} => ".json_encode($data));
                    else $batch->set($doc, $data, ['merge'=>true]);

                    $n++;
                    if ($n >= 450 && !$this->dry) {
                        $batch->commit();
                        $batch = $this->fs->batch();
                        $n = 0;
                    }
                }
                if (!$this->dry) $batch->commit();
            });

        $this->ok();
    }

    /** Map attendance_records -> /sessions/{sid}/records/{studentUid} */
    protected function exportAttendanceRecords(): void
    {
        $this->section('AttendanceRecords -> /sessions/{sid}/records/{uid}');
        $chunk = (int)$this->option('chunk');
        $from  = (int)$this->option('from');

        DB::table('attendance_records')
            ->where('attendance_session_id', '>=', $from) // resume theo session id (tuỳ bạn)
            ->orderBy('attendance_session_id')
            ->chunk($chunk, function ($rows) {
                // nhóm theo session
                $grouped = [];
                foreach ($rows as $r) {
                    $grouped[$r->attendance_session_id][] = $r;
                }

                foreach ($grouped as $sid => $list) {
                    $batch = $this->fs->batch();
                    $n = 0;
                    foreach ($list as $r) {
                        $stu = DB::table('students')->where('id',$r->student_id)->first();
                        $uid = $stu?->user_id ? ('laravel-'.$stu->user_id) : null;
                        if (!$uid) continue;

                        $data = [
                            'status' => $r->status,
                            'photoUrl' => $r->photo_path ?: null,
                            'gps_lat' => is_null($r->gps_lat) ? null : (float)$r->gps_lat,
                            'gps_lng' => is_null($r->gps_lng) ? null : (float)$r->gps_lng,
                            'note'    => $r->note,
                            'created_at' => $this->ts($r->created_at),
                        ];
                        $doc = $this->fs->collection('sessions')->document((string)$sid)
                            ->collection('records')->document($uid);
                        if ($this->dry) $this->line("DRY sessions/$sid/records/$uid => ".json_encode($data));
                        else $batch->set($doc, $data, ['merge'=>true]);

                        $n++;
                        if ($n >= 450 && !$this->dry) {
                            $batch->commit();
                            $batch = $this->fs->batch();
                            $n = 0;
                        }
                    }
                    if (!$this->dry) $batch->commit();
                }
            });

        $this->ok();
    }

    // ===== helpers =====

    protected function ts($v)
    {
        if (!$v) return null;
        try {
            return new \DateTime($v);
        } catch (\Throwable $e) {
            return null;
        }
    }
    protected function dt($v)
    {
        if (!$v) return null;
        try {
            return (new \DateTime($v))->format(\DateTime::ATOM); // ISO 8601
        } catch (\Throwable $e) {
            return null;
        }
    }
    protected function date($v)
    {
        if (!$v) return null;
        try {
            return (new \DateTime($v))->format('Y-m-d');
        } catch (\Throwable $e) {
            return null;
        }
    }
    protected function json($v)
    {
        if (is_array($v)) return $v;
        if (is_string($v)) {
            $d = json_decode($v, true);
            return $d ?: null;
        }
        return null;
    }

    protected function section(string $title): void
    {
        $this->info("\n--- $title ---");
    }
    protected function ok(): void
    {
        $this->info("OK");
    }
}
