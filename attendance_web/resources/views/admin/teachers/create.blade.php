@extends('layouts.app')
@section('title','Thêm giảng viên')

@section('content')
    <div class="section-title"><h2>Thêm giảng viên</h2></div>
    <div class="card" style="max-width:720px">
        <form method="post" action="{{ route('admin.teachers.store') }}">
            @csrf

            <label>Họ tên</label>
            <input class="form-control" name="name" value="{{ old('name') }}" required>

            <label style="margin-top:8px">Email</label>
            <input class="form-control" type="email" name="email" value="{{ old('email') }}" required>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:8px">
                <div>
                    <label>Mã giảng viên</label>
                    <input class="form-control" name="teacher_code" value="{{ old('teacher_code') }}" required>
                </div>
                <div>
                    <label>Bộ môn (tuỳ chọn)</label>
                    <select class="form-control" name="department_id">
                        <option value="">-- Chưa chọn --</option>
                        @foreach($departments as $d)
                            <option value="{{ $d->id }}" @selected(old('department_id')==$d->id)>{{ $d->name }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div style="margin-top:12px;display:flex;gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.teachers.index') }}">Huỷ</a>
                <button class="btn">Lưu</button>
            </div>
        </form>
    </div>
@endsection
