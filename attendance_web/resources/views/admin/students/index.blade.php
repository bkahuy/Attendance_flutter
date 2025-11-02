@extends('layouts.app')
@section('title','Quản lý sinh viên')

@section('content')
    <div class="section-title"><h2>Quản lý sinh viên</h2></div>

    <form method="get" class="toolbar">
        <div class="input-icon">
            <input class="form-control" name="search" value="{{ request('search') }}" placeholder="Tìm kiếm theo tên sinh viên">
        </div>

        <div class="input-icon" style="min-width:200px">
            <input class="form-control" name="student_code" value="{{ request('student_code') }}" placeholder="Mã sinh viên">
        </div>

        <div class="input-icon" style="min-width:200px">
            <select class="form-control" name="faculty">
                <option value="">Khoa</option>
                @foreach(['Công nghệ thông tin','Kinh tế','Xây dựng'] as $f)
                    <option value="{{ $f }}" @selected(request('faculty')==$f)>{{ $f }}</option>
                @endforeach
            </select>
        </div>

        <div class="input-icon" style="min-width:200px">
            <select class="form-control" name="class_name">
                <option value="">Lớp</option>
                @foreach(['CNTT1','CNTT2','KTPM1','KTPM2','HTTT1'] as $c)
                    <option value="{{ $c }}" @selected(request('class_name')==$c)>{{ $c }}</option>
                @endforeach
            </select>
        </div>

        <button class="icon-btn" title="Tìm">Tìm kiếm</button>

        <div class="spacer"></div>
        <a class="btn" href="{{ route('admin.students.create') }}">Thêm sinh viên</a>
    </form>


    <div class="card table">
        <table>
            <thead>
            <tr>
                <th>MSSV</th><th>Họ tên</th><th>Email</th><th>Lớp</th><th>Khoa</th><th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @foreach($students as $st)
                <tr>
                    <td>{{ $st->student_code }}</td>
                    <td>{{ $st->user->name ?? '' }}</td>
                    <td>{{ $st->user->email ?? '' }}</td>
                    <td>{{ $st->class_name ?? '—' }}</td>
                    <td>{{ $st->faculty ?? '—' }}</td>
                    <td>
                        <a class="btn btn-outline" href="{{ route('admin.students.edit',$st->id) }}">Sửa</a>
                        <form action="{{ route('admin.students.destroy',$st->id) }}" method="post" style="display:inline" onsubmit="return confirm('Xoá?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-danger">Xoá</button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
        {{ $students->links() }}
    </div>
@endsection
