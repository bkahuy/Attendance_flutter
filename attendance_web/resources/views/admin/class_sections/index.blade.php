<?php
@extends('layouts.app')
@section('content')
    <div class="d-flex justify-content-between mb-3">
        <h5 class="mb-0">Class Sections</h5>
        <a href="{{ route('class-sections.create') }}" class="btn btn-primary">+ New Class</a>
    </div>
    <div class="card">
        <div class="table-responsive">
            <table class="table table-hover mb-0 align-middle">
                <thead><tr><th>#</th><th>Course</th><th>Teacher</th><th>Term</th><th>Room</th><th>Capacity</th><th>Lịch</th><th></th></tr></thead>
                <tbody>
                @foreach($classes as $cs)
                    <tr>
                        <td>{{ $cs->id }}</td>
                        <td>{{ $cs->course->code }} - {{ $cs->course->name }}</td>
                        <td>{{ $cs->teacher->user->name ?? 'N/A' }}</td>
                        <td>{{ $cs->term }}</td>
                        <td>{{ $cs->room }}</td>
                        <td>{{ $cs->capacity }}</td>
                        <td>
                            {{-- Quick add recurring schedule --}}
                            <form class="row gx-1 gy-1" method="POST" action="{{ route('schedules.store') }}">
                                @csrf
                                <input type="hidden" name="class_section_id" value="{{ $cs->id }}">
                                <div class="col-auto">
                                    <select name="weekday" class="form-select form-select-sm">
                                        @foreach([0=>'Sun',1=>'Mon',2=>'Tue',3=>'Wed',4=>'Thu',5=>'Fri',6=>'Sat'] as $k=>$v)
                                            <option value="{{ $k }}">{{ $v }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div class="col-auto"><input type="time" name="start_time" class="form-control form-control-sm" required></div>
                                <div class="col-auto"><input type="time" name="end_time" class="form-control form-control-sm" required></div>
                                <div class="col-auto">
                                    <input type="hidden" name="recurring_flag" value="1">
                                    <button class="btn btn-sm btn-outline-success">Add</button>
                                </div>
                            </form>
                        </td>
                        <td class="text-end">
                            <a class="btn btn-sm btn-outline-primary" href="{{ route('class-sections.edit',$cs) }}">Sửa</a>
                            <form class="d-inline" method="POST" action="{{ route('class-sections.destroy',$cs) }}" onsubmit="return confirm('Xoá lớp?')">
                                @csrf @method('DELETE') <button class="btn btn-sm btn-outline-danger">Xoá</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
        <div class="card-footer">{{ $classes->links() }}</div>
    </div>
@endsection
