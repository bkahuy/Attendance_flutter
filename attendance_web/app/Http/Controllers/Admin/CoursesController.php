<?php


namespace App\Http\Controllers\Admin;


use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\Request;


class CoursesController extends Controller
{
    public function index() { return Course::orderBy('code')->paginate(50); }
    public function store(Request $r) { $c = Course::create($r->validate(['code'=>'required|unique:courses','name'=>'required','credits'=>'integer|min:1'])); return response()->json($c,201);}
    public function show($id) { return Course::findOrFail($id); }
    public function update(Request $r,$id){ $c=Course::findOrFail($id); $c->update($r->only('code','name','credits')); return $c; }
    public function destroy($id){ Course::destroy($id); return response()->json(['message'=>'Deleted']); }
}
