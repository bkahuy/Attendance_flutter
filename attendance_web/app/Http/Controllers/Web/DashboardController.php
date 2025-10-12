<?php
namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\{User,Course,ClassSection,AttendanceRecord};

class DashboardController extends Controller
{
    public function index()
    {
        return view('dashboard', [
            'usersCount' => User::count(),
            'coursesCount' => Course::count(),
            'classesCount' => ClassSection::count(),
            'recordsCount' => AttendanceRecord::count(),
        ]);
    }
}
