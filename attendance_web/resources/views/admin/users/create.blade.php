@extends('layouts.app')
@section('content')
    <div class="card">
        <div class="card-body">
            <h5 class="mb-3">Tạo User</h5>

            {{-- Hiển thị lỗi validate (nếu có) --}}
            @if ($errors->any())
                <div class="alert alert-danger">
                    <ul class="mb-0">
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form method="POST" action="{{ route('users.store') }}">
                @csrf
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">Name</label>
                        <input name="name" class="form-control" value="{{ old('name') }}" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Email</label>
                        <input name="email" type="email" class="form-control" value="{{ old('email') }}" required>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Role</label>
                        <select name="role" id="role-select" class="form-select" required>
                            <option value="admin"   {{ old('role')==='admin'?'selected':'' }}>admin</option>
                            <option value="teacher" {{ old('role','student')==='teacher'?'selected':'' }}>teacher</option>
                            <option value="student" {{ old('role','student')==='student'?'selected':'' }}>student</option>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Phone</label>
                        <input name="phone" class="form-control" value="{{ old('phone') }}">
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-select">
                            <option value="active"   {{ old('status')==='active'?'selected':'' }}>active</option>
                            <option value="inactive" {{ old('status')==='inactive'?'selected':'' }}>inactive</option>
                            <option value="blocked"  {{ old('status')==='blocked'?'selected':'' }}>blocked</option>
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Password (optional)</label>
                        <input name="password" type="password" class="form-control">
                        {{-- Gợi ý: nếu để trống, phía controller có thể đặt mặc định "12345678" --}}
                    </div>
                </div>

                {{-- ========= KHỐI THÔNG TIN STUDENT (ẩn/hiện theo role) ========= --}}
                <div id="role-student" class="mt-3" style="display:none;">
                    <div class="border rounded p-3">
                        <h6 class="mb-3">Thông tin Student</h6>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label">Mã SV</label>
                                <input name="student_code" class="form-control" value="{{ old('student_code') }}">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Khoa</label>
                                <input name="faculty" class="form-control" value="{{ old('faculty') }}">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Lớp</label>
                                <input name="class_name" class="form-control" value="{{ old('class_name') }}">
                            </div>
                        </div>
                    </div>
                </div>

                {{-- ========= KHỐI THÔNG TIN TEACHER (ẩn/hiện theo role) ========= --}}
                <div id="role-teacher" class="mt-3" style="display:none;">
                    <div class="border rounded p-3">
                        <h6 class="mb-3">Thông tin Teacher</h6>
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Bộ môn</label>
                                <input name="department" class="form-control" value="{{ old('department') }}">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Chức danh</label>
                                <input name="title" class="form-control" value="{{ old('title') }}">
                            </div>
                        </div>
                    </div>
                </div>

                <div class="mt-3">
                    <button class="btn btn-primary">Lưu</button>
                    <a href="{{ route('users.index') }}" class="btn btn-outline-secondary">Hủy</a>
                </div>
            </form>
        </div>
    </div>

    {{-- JS toggle theo role --}}
    <script>
        (function () {
            const sel = document.getElementById('role-select');
            const studentBox = document.getElementById('role-student');
            const teacherBox = document.getElementById('role-teacher');

            function toggle() {
                const v = sel.value;
                studentBox.style.display = (v === 'student') ? 'block' : 'none';
                teacherBox.style.display = (v === 'teacher') ? 'block' : 'none';
            }
            sel.addEventListener('change', toggle);
            toggle(); // chạy lần đầu
        })();
    </script>
@endsection
