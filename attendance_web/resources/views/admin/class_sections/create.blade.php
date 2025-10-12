<?php
@extends('layouts.app')
@section('content')
    <div class="card"><div class="card-body">
            <h5 class="mb-3">Tạo Class Section</h5>
            <form method="POST" action="{{ route('class-sections.store') }}">
                @csrf
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label">Course</label>
                        <select name="course_id" class="form-select" required>
                            @foreach($courses as $c)<option value="{{ $c->id }}">{{ $c->code }} - {{ $c->name }}</option>@endforeach
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Teacher</label>
                        <select name="teacher_id" class="form-select" required>
                            @foreach($teachers as $t)<option value="{{ $t->id }}">{{ $t->user->name }}</option>@endforeach
                        </select>
                    </div>
                    <div class="col-md-4"><label class="form-label">Term</label><input name="term" class="form-control" required></div>
                    <div class="col-md-3"><label class="form-label">Room</label><input name="room" class="form-control"></div>
                    <div class="col-md-3"><label class="form-label">Capacity</label><input name="capacity" type="number" min="1" class="form-control"></div>
                    <div class="col-md-3"><label class="form-label">Start date</label><input name="start_date" type="date" class="form-control"></div>
                    <div class="col-md-3"><label class="form-label">End date</label><input name="end_date" type="date" class="form-control"></div>
                </div>
                <div class="mt-3"><button class="btn btn-primary">Lưu</button></div>
            </form>
        </div></div>
@endsection
