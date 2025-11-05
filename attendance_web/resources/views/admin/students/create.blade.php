@extends('layouts.app')
@section('title','Thêm sinh viên')

@section('content')
    <div class="section-title"><h2>Thêm sinh viên</h2></div>

    @if ($errors->any())
        <div class="flash" style="background:#fef2f2;color:#991b1b;border-color:#fecaca">
            {{ $errors->first() }}
        </div>
    @endif

    <form method="post" action="{{ route('admin.students.store') }}" class="card" style="display:grid;gap:12px">
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
            <label>MSSV</label>
            <input name="student_code" class="form-control" value="{{ old('student_code') }}" required>
        </div>

        <div>
            <label>Lớp</label>
            @php $selected = old('class_id'); @endphp
            <select name="class_id" id="class_id" class="form-control">
                <option value="">— Chọn lớp —</option>
                @foreach($classes as $c)
                    @php
                        $optId      = $c->id;
                        $optName    = $c->name;
                        $optFaculty = $c->major->faculty->name ?? '';
                    @endphp
                    <option value="{{ $optId }}"
                            data-faculty="{{ $optFaculty }}"
                        {{ (string)$selected === (string)$optId ? 'selected' : '' }}>
                        {{ $optName }} @if($optFaculty) — {{ $optFaculty }} @endif
                    </option>
                @endforeach
            </select>

            <input id="faculty_display" class="form-control" value="" disabled>
        </div>

        <div>
            <button class="btn">Lưu</button>
            <a class="btn btn-outline" href="{{ route('admin.students.index') }}">Huỷ</a>
        </div>
    </form>

    @push('scripts')
        <script>
            document.addEventListener('DOMContentLoaded', function(){
                var sel = document.getElementById('class_id');
                var out = document.getElementById('faculty_display');
                function syncFaculty(){
                    var opt = sel.options[sel.selectedIndex];
                    out.value = opt ? (opt.getAttribute('data-faculty') || '') : '';
                }
                sel.addEventListener('change', syncFaculty);
                syncFaculty();
            });
        </script>
    @endpush
@endsection
