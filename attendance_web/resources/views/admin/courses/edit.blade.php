@extends('layouts.app')
@section('title','Sửa môn học')

@section('content')
    <div class="section-title">
        <h2>Sửa môn học</h2>
    </div>

    @component('components.card')
        <form method="post" action="{{ route('admin.courses.update',$course->id) }}" style="max-width:640px">
            @csrf @method('PUT')

            <label>Mã môn</label>
            <input class="form-control" name="code" value="{{ old('code',$course->code) }}" required>

            <label>Tên môn học</label>
            <input class="form-control" name="name" value="{{ old('name',$course->name) }}" required>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
                <div>
                    <label>Tín chỉ</label>
                    <input class="form-control" type="number" min="1" max="10"
                           name="credits" value="{{ old('credits',$course->credits) }}" required>
                </div>
                <div>
                    <label>Bộ môn (tuỳ chọn)</label>
                    <select class="form-control" name="department_id">
                        <option value="">-- Chưa chọn --</option>
                        @foreach($departments as $d)
                            <option value="{{ $d->id }}" @selected(old('department_id',$course->department_id)==$d->id)>
                                {{ $d->name }}
                            </option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div style="margin-top:12px;display:flex;gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.courses.index') }}">Quay lại</a>
                <button class="btn">Cập nhật</button>
            </div>
        </form>
    @endcomponent
@endsection
