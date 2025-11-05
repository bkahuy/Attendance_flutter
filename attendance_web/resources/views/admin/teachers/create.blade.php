@extends('layouts.app')
@section('title','Thêm giảng viên')

@section('content')
    <div class="section-title"><h2>Thêm giảng viên</h2></div>

    <form method="post" action="{{ route('admin.teachers.store') }}" class="card" style="display:grid;gap:12px">
        @csrf

        <div>
            <label>Họ tên</label>
            <input name="name" class="form-control" value="{{ old('name') }}" required>
        </div>

        <div>
            <label>Email</label>
            <input name="email" type="email" class="form-control" value="{{ old('email') }}" required>
        </div>

        <div>
            <label>Số điện thoại</label>
            <input name="phone" class="form-control" value="{{ old('phone') }}" placeholder="VD: 09xxxxxxxx">
        </div>

        <div>
            <label>Mã giảng viên</label>
            <input name="teacher_code" class="form-control" value="{{ old('teacher_code') }}" required>
        </div>

        <div>
            <label>Bộ môn</label>
            <select name="department_id" id="department_id" class="form-control" required>
                <option value="">— Chọn bộ môn —</option>
                @foreach($departments as $d)
                    <option value="{{ $d->id }}" data-faculty="{{ $d->faculty->name ?? '' }}"
                        @selected(old('department_id')==$d->id)>
                        {{ $d->name }}
                    </option>
                @endforeach
            </select>
        </div>

        <div>
            <label>Khoa (tự động theo bộ môn)</label>
            <input id="faculty_display" class="form-control" value="" disabled>
        </div>

        <div>
            <button class="btn">Lưu</button>
            <a class="btn btn-outline" href="{{ route('admin.teachers.index') }}">Huỷ</a>
        </div>
    </form>

    @push('scripts')
        <script>
            document.addEventListener('DOMContentLoaded', function(){
                var sel = document.getElementById('department_id');
                var out = document.getElementById('faculty_display');
                function sync() {
                    var opt = sel.options[sel.selectedIndex];
                    out.value = opt ? (opt.getAttribute('data-faculty') || '') : '';
                }
                sel.addEventListener('change', sync);
                sync();
            });
        </script>
    @endpush
@endsection
