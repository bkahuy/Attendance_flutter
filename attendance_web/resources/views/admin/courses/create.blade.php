@extends('layouts.app')
@section('title','Thêm môn học')

@section('content')
    <div class="section-title"><h2>Thêm môn học</h2></div>
    @component('components.card')
        <form method="post" action="{{ route('admin.courses.store') }}" style="max-width:640px">
            @csrf
            <label>Mã môn</label>
            <input class="form-control" name="code" value="{{ old('code') }}" required>

            <label>Tên môn học</label>
            <input class="form-control" name="name" value="{{ old('name') }}" required>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
                <div>
                    <label>Tín chỉ</label>
                    <input class="form-control" type="number" min="1" max="10" name="credits" value="{{ old('credits',3) }}" required>
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
                <a class="btn btn-outline" href="{{ route('admin.courses.index') }}">Huỷ</a>
                <button class="btn">Lưu</button>
            </div>
        </form>
    @endcomponent
@endsection
