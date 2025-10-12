<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Teacher;
use App\Models\Student;

class TestAccountsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // ADMIN
        $admin = User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name'     => 'Admin',
                'password' => Hash::make('admin123'),
                'role'     => 'admin',
                'status'   => 'active',
                'phone'    => '0900000000',
            ]
        );

        // TEACHER
        $teacherUser = User::updateOrCreate(
            ['email' => 'teacher1@example.com'],
            [
                'name'     => 'GV 1',
                'password' => Hash::make('pass123'),
                'role'     => 'teacher',
                'status'   => 'active',
                'phone'    => '0900000001',
            ]
        );
        Teacher::updateOrCreate(
            ['user_id' => $teacherUser->id],
            ['teacher_code' => 'GV001', 'dept' => 'CNTT']
        );

        // STUDENT
        $studentUser = User::updateOrCreate(
            ['email' => 'student1@example.com'],
            [
                'name'     => 'SV 1',
                'password' => Hash::make('pass123'),
                'role'     => 'student',
                'status'   => 'active',
                'phone'    => '0900000002',
            ]
        );
        Student::updateOrCreate(
            ['user_id' => $studentUser->id],
            ['student_code' => 'SV001', 'faculty' => 'CNTT', 'class_name' => 'K17', 'extra_info' => null]
        );

        $this->command?->info('Seeded:');
        $this->command?->info('- admin@example.com / admin123 (admin)');
        $this->command?->info('- teacher1@example.com / pass123 (teacher)');
        $this->command?->info('- student1@example.com / pass123 (student)');
    }
}
