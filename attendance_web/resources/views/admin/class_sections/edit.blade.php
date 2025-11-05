@extends('layouts.app')
@section('title','Sửa lớp học phần')

@section('content')
    <div class="section-title"><h2>Sửa lớp học phần #{{ $section->id }}</h2></div>
    @component('components.card')
        <form method="post" action="{{ route('admin.class-sections.update',$section->id) }}" style="max-width:720px">
            @csrf @method('PUT')

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
                <div>
                    <label>Môn học</label>
                    <select class="form-control" name="course_id" required>
                        @foreach($courses as $c)
                            <option value="{{ $c->id }}" @selected($section->course_id==$c->id)>{{ $c->code }} - {{ $c->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label>Giảng viên</label>
                    <select class="form-control" name="teacher_id" required>
                        @foreach($teachers as $t)
                            <option value="{{ $t->id }}" @selected($section->teacher_id==$t->id)>{{ $t->user->name ?? ('GV #'.$t->id) }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;margin-top:10px">
                <div>
                    <label>Ngành/Chuyên ngành</label>
                    <select class="form-control" name="major_id">
                        <option value="">-- Không --</option>
                        @foreach($majors as $m)
                            <option value="{{ $m->id }}" @selected($section->major_id==$m->id)>{{ $m->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label>Kỳ học</label>
                    <select class="form-control" name="term">
                        <option value="">-- Chưa đặt --</option>
                        @foreach($termOptions as $t)
                            <option value="{{ $t }}" @selected(old('term',$section->term)==$t)>{{ $t }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label>Phòng</label>
                    <input class="form-control" name="room" value="{{ old('room',$section->room) }}">
                </div>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;margin-top:10px">
                <div>
                    <label>Sĩ số</label>
                    <input class="form-control" type="number" min="1" max="500" name="capacity" value="{{ old('capacity',$section->capacity) }}">
                </div>
                <div>
                    <label>Ngày bắt đầu</label>
                    <input class="form-control" type="date" name="start_date" value="{{ old('start_date',$section->start_date) }}">
                </div>
                <div>
                    <label>Ngày kết thúc</label>
                    <input class="form-control" type="date" name="end_date" value="{{ old('end_date',$section->end_date) }}">
                </div>
            </div>

            <div style="margin-top:12px;display:flex;gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.class-sections.index') }}">Quay lại</a>
                <button class="btn">Lưu</button>
            </div>
        </form>
    @endcomponent
@endsection
