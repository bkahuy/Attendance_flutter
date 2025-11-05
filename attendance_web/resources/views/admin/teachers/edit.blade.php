@extends('layouts.app')
@section('title','Sửa giảng viên')

@section('content')
    <div class="section-title"><h2>Sửa giảng viên</h2></div>

    <form method="post" action="{{ route('admin.teachers.update',$teacher->id) }}" class="card" style="display:grid;gap:12px">
        @csrf @method('PUT')

        <div>
            <label>Họ tên</label>
            <input name="name" class="form-control" value="{{ old('name', $teacher->user->name) }}" required>
            @error('name') <small style="color:#b91c1c">{{ $message }}</small> @enderror
        </div>

        <div>
            <label>Email</label>
            <input name="email" type="email" class="form-control" value="{{ old('email', $teacher->user->email) }}" required>
            @error('email') <small style="color:#b91c1c">{{ $message }}</small> @enderror
        </div>

        <div>
            <label>Số điện thoại</label>
            <input name="phone" class="form-control" value="{{ old('phone', $teacher->user->phone) }}" placeholder="VD: 09xxxxxxxx">
            @error('phone') <small style="color:#b91c1c">{{ $message }}</small> @enderror
        </div>

        <div>
            <label>Mã giảng viên</label>
            <input name="teacher_code" class="form-control" value="{{ old('teacher_code', $teacher->teacher_code) }}" required>
            @error('teacher_code') <small style="color:#b91c1c">{{ $message }}</small> @enderror
        </div>

        <div>
            <label>Bộ môn</label>
            <select name="department_id" id="department_id" class="form-control" required>
                <option value="">— Chọn bộ môn —</option>
                @foreach($departments as $d)
                    <option value="{{ $d->id }}" data-faculty="{{ $d->faculty->name ?? '' }}"
                        @selected(old('department_id', $teacher->department_id)==$d->id)>
                        {{ $d->name }}
                    </option>
                @endforeach
            </select>
            @error('department_id') <small style="color:#b91c1c">{{ $message }}</small> @enderror
        </div>

        <div>
            <label>Khoa (tự động theo bộ môn)</label>
            <input id="faculty_display" class="form-control" value="{{ $teacher->department->faculty->name ?? '' }}" disabled>
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
