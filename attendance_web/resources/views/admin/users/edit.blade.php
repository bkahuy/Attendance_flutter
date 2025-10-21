@extends('layouts.app')
@section('content')
    <div class="card">
        <div class="card-body">
            <h5 class="mb-3">Sửa User #{{ $user->id }}</h5>

            {{-- Lỗi validate (nếu có) --}}
            @if ($errors->any())
                <div class="alert alert-danger">
                    <ul class="mb-0">
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form method="POST" action="{{ route('users.update',$user) }}">
                @csrf @method('PUT')
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">Name</label>
                        <input name="name" class="form-control" value="{{ old('name', $user->name) }}" required>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">Email</label>
                        <input name="email" type="email" class="form-control" value="{{ old('email', $user->email) }}" required>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Role</label>
                        <select name="role" id="role-select" class="form-select" required>
                            @foreach(['admin','teacher','student'] as $r)
                                <option value="{{ $r }}" {{ old('role', $user->role)===$r ? 'selected' : '' }}>{{ $r }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Phone</label>
                        <input name="phone" class="form-control" value="{{ old('phone', $user->phone) }}">
                    </div>

                    <div class="col-md-4">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-select">
                            @foreach(['active','inactive','blocked'] as $s)
                                <option value="{{ $s }}" {{ old('status', $user->status)===$s ? 'selected' : '' }}>{{ $s }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label">New Password</label>
                        <input name="password" type="password" class="form-control" placeholder="Để trống nếu không đổi">
                    </div>
                </div>

                {{-- ========= KHỐI THÔNG TIN STUDENT (ẩn/hiện theo role) ========= --}}
                <div id="role-student" class="mt-3" style="display:none;">
                    <div class="border rounded p-3">
                        <h6 class="mb-3">Thông tin Student</h6>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label">Mã SV</label>
                                <input name="student_code" class="form-control"
                                       value="{{ old('student_code', optional($user->student)->student_code) }}">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Khoa</label>
                                <input name="faculty" class="form-control"
                                       value="{{ old('faculty', optional($user->student)->faculty) }}">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Lớp</label>
                                <input name="class_name" class="form-control"
                                       value="{{ old('class_name', optional($user->student)->class_name) }}">
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
                                <input name="department" class="form-control"
                                       value="{{ old('department', optional($user->teacher)->department) }}">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Chức danh</label>
                                <input name="title" class="form-control"
                                       value="{{ old('title', optional($user->teacher)->title) }}">
                            </div>
                        </div>
                    </div>
                </div>

                <div class="mt-3">
                    <button class="btn btn-primary">Cập nhật</button>
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
            toggle(); // khởi chạy theo role hiện tại
        })();
    </script>
@endsection
