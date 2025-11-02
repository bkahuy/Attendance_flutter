@extends('layouts.app')
@section('title','Quản lý giảng viên')

@section('content')
    <div class="section-title"><h2>Quản lý giảng viên</h2></div>

    <form method="get" class="toolbar">
        <div class="input-icon">
            <input class="form-control" name="search" value="{{ request('search') }}" placeholder="Tìm kiếm theo tên giảng viên">
        </div>

        <div class="input-icon" style="min-width:200px">
            <input class="form-control" name="teacher_code" value="{{ request('teacher_code') }}" placeholder="Mã giảng viên">
        </div>

        <div class="input-icon" style="min-width:220px">
            <select class="form-control" name="department_id">
                <option value="">Khoa</option>
                @foreach(\App\Models\Department::orderBy('name')->get() as $d)
                    <option value="{{ $d->id }}" @selected(request('department_id')==$d->id)>{{ $d->name }}</option>
                @endforeach
            </select>
        </div>

        <button class="icon-btn" title="Tìm">Tìm kiếm</button>

        <div class="spacer"></div>
        <a class="btn" href="{{ route('admin.teachers.create') }}">Thêm giảng viên</a>
    </form>


    <div class="card table">
        <table>
            <thead>
            <tr>
                <th>Mã GV</th><th>Họ tên</th><th>Email</th><th>Bộ môn</th><th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @foreach($teachers as $t)
                <tr>
                    <td>{{ $t->teacher_code }}</td>
                    <td>{{ $t->user->name ?? '' }}</td>
                    <td>{{ $t->user->email ?? '' }}</td>
                    <td>{{ $t->department->name ?? '—' }}</td>
                    <td>
                        <a class="btn btn-outline" href="{{ route('admin.teachers.edit',$t->id) }}">Sửa</a>
                        <form action="{{ route('admin.teachers.destroy',$t->id) }}" method="post" style="display:inline" onsubmit="return confirm('Xoá?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-danger">Xoá</button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
        {{ $teachers->links() }}
    </div>
@endsection
