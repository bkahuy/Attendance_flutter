@extends('layouts.app')
@section('title','Thêm sinh viên')

@section('content')
    <div class="section-title"><h2>Thêm sinh viên</h2></div>
    <div class="card" style="max-width:720px">
        <form method="post" action="{{ route('admin.students.store') }}">
            @csrf
            <label>Họ tên</label>
            <input class="form-control" name="name" value="{{ old('name') }}" required>

            <label style="margin-top:8px">Email</label>
            <input class="form-control" type="email" name="email" value="{{ old('email') }}" required>

            <label style="margin-top:8px">MSSV</label>
            <input class="form-control" name="student_code" value="{{ old('student_code') }}" required>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:8px">
                <div>
                    <label>Lớp</label>
                    <select class="form-control" name="class_name">
                        <option value="">-- Chọn lớp --</option>
                        @foreach($classes as $c)
                            <option value="{{ $c }}" @selected(old('class_name')==$c)>{{ $c }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label>Khoa</label>
                    <select class="form-control" name="faculty">
                        <option value="">-- Chọn khoa --</option>
                        @foreach($faculties as $f)
                            <option value="{{ $f }}" @selected(old('faculty')==$f)>{{ $f }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div style="margin-top:12px;display:flex;gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.students.index') }}">Huỷ</a>
                <button class="btn">Lưu</button>
            </div>
        </form>
    </div>
@endsection
