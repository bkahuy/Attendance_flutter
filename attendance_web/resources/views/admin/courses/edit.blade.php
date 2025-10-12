<?php
@extends('layouts.app')
@section('content')
    <div class="card"><div class="card-body">
            <h5 class="mb-3">{{ isset($course) ? 'Sửa' : 'Tạo' }} Course</h5>
            <form method="POST" action="{{ isset($course)?route('courses.update',$course):route('courses.store') }}">
                @csrf @if(isset($course)) @method('PUT') @endif
                <div class="row g-3">
                    <div class="col-md-3"><label class="form-label">Code</label><input name="code" class="form-control" value="{{ $course->code ?? '' }}" required></div>
                    <div class="col-md-7"><label class="form-label">Name</label><input name="name" class="form-control" value="{{ $course->name ?? '' }}" required></div>
                    <div class="col-md-2"><label class="form-label">Credits</label><input name="credits" type="number" min="1" class="form-control" value="{{ $course->credits ?? 3 }}" required></div>
                </div>
                <div class="mt-3"><button class="btn btn-primary">Lưu</button></div>
            </form>
        </div></div>
@endsection
