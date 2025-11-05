@extends('layouts.app')
@section('title','Quản lý giảng viên')

@section('content')
    <div class="section-title">
        <h2>Quản lý giảng viên</h2>
        <a class="btn" href="{{ route('admin.teachers.create') }}">Thêm giảng viên</a>
    </div>

    @component('components.card')
        <form method="get" class="toolbar split">
            <div class="toolbar-left">
                <div class="input-icon" style="min-width:260px">
                    <input class="form-control" name="search" value="{{ request('search') }}" placeholder="Tìm theo tên / email / SĐT / mã GV">
                </div>

                <div class="input-icon" style="min-width:160px">
                    <input class="form-control" name="teacher_code" value="{{ request('teacher_code') }}" placeholder="Mã giảng viên">
                </div>

                <div class="input-icon" style="min-width:200px">
                    <select class="form-control" name="department_id">
                        <option value="">Bộ môn</option>
                        @foreach($departments as $d)
                            <option value="{{ $d->id }}" @selected(request('department_id')==$d->id)>{{ $d->name }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="input-icon" style="min-width:200px">
                    <select class="form-control" name="faculty_id">
                        <option value="">Khoa</option>
                        @foreach($faculties as $f)
                            <option value="{{ $f->id }}" @selected(request('faculty_id')==$f->id)>{{ $f->name }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="toolbar-right">
                <a class="btn btn-outline" href="{{ route('admin.teachers.index') }}">Reset</a>
                <button class="btn btn-brand" style="color: whitesmoke">Tìm</button>
            </div>
        </form>
    @endcomponent

    <div class="card table">
        <table>
            <thead>
            <tr>
                <th>Mã GV</th><th>Họ tên</th><th>Email</th><th>SĐT</th><th>Bộ môn</th><th>Khoa</th><th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @foreach($teachers as $t)
                <tr>
                    <td>{{ $t->teacher_code }}</td>
                    <td>{{ $t->user->name ?? '' }}</td>
                    <td>{{ $t->user->email ?? '' }}</td>
                    <td>{{ $t->user->phone ?? '' }}</td> {{-- <= cột SĐT cạnh email --}}
                    <td>{{ $t->department->name ?? '—' }}</td>
                    <td>{{ $t->department?->faculty?->name ?? '—' }}</td>
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
        {{ $teachers->onEachSide(1)->withQueryString()->links() }}
    </div>
@endsection
