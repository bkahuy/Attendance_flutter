<?php
@extends('layouts.app')

@section('content')
    <div class="row g-3">
        <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted">Users</div><div class="h3">{{ $usersCount }}</div></div></div></div>
        <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted">Courses</div><div class="h3">{{ $coursesCount }}</div></div></div></div>
        <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted">Class Sections</div><div class="h3">{{ $classesCount }}</div></div></div></div>
        <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted">Attendance Records</div><div class="h3">{{ $recordsCount }}</div></div></div></div>
    </div>
@endsection
