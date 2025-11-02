@extends('layouts.app')
@section('title','Quản lý lớp học phần')

@section('content')
    <div class="section-title">
        <h2>Quản lý lớp học phần</h2>
        <form method="get" style="display:flex;gap:10px;flex-wrap:wrap">
            <select class="form-control" name="course_id">
                <option value="">-- Môn học --</option>
                @foreach($courses as $c)
                    <option value="{{ $c->id }}" @selected(request('course_id')==$c->id)>{{ $c->code }} - {{ $c->name }}</option>
                @endforeach
            </select>
            <select class="form-control" name="teacher_id">
                <option value="">-- Giảng viên --</option>
                @foreach($teachers as $t)
                    <option value="{{ $t->id }}" @selected(request('teacher_id')==$t->id)>{{ $t->user->name ?? 'GV #'.$t->id }}</option>
                @endforeach
            </select>
            <button class="btn">Lọc</button>
            <a class="btn btn-outline" href="{{ route('admin.class-sections.create') }}">Thêm lớp HP</a>
        </form>
    </div>

    @component('components.card')
        <table class="table">
            <thead>
            <tr><th>ID</th><th>Môn học</th><th>Giảng viên</th><th>Kì</th><th>Phòng</th><th>SL</th><th>Ngày</th><th style="width:160px">Hành động</th></tr>
            </thead>
            <tbody>
            @foreach($sections as $s)
                <tr>
                    <td>#{{ $s->id }}</td>
                    <td>{{ $s->course->code ?? '' }} - {{ $s->course->name ?? '' }}</td>
                    <td>{{ $s->teacher->user->name ?? '' }}</td>
                    <td>{{ $s->term }}</td>
                    <td>{{ $s->room }}</td>
                    <td>{{ $s->capacity }}</td>
                    <td>{{ $s->start_date }} → {{ $s->end_date }}</td>
                    <td>
                        <a class="btn btn-outline" href="{{ route('admin.class-sections.edit',$s->id) }}">Sửa</a>
                        <form action="{{ route('admin.class-sections.destroy',$s->id) }}" method="post" style="display:inline" onsubmit="return confirm('Xoá?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-danger">Xoá</button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
        {{ $sections->links() }}
    @endcomponent
@endsection
