@extends('layouts.app')
@section('title','Quản lý sinh viên')

@section('content')
    <div class="section-title">
        <h2>Quản lý sinh viên</h2>
        <a class="btn" href="{{ route('admin.students.create') }}">Thêm sinh viên</a>
    </div>

    @component('components.card')
        <form method="get" class="toolbar split">
            <div class="toolbar-left">
                <div class="input-icon" style="min-width:260px">
                    <input class="form-control" name="search" value="{{ request('search') }}" placeholder="Tìm theo tên/email/SĐT/MSSV">
                </div>

                <div class="input-icon" style="min-width:160px">
                    <input class="form-control" name="student_code" value="{{ request('student_code') }}" placeholder="MSSV">
                </div>

                @php($faculties = $faculties ?? collect())
                @if($faculties->count())
                    <div class="input-icon" style="min-width:200px">
                        <select class="form-control" name="faculty_id">
                            <option value="">Khoa</option>
                            @foreach($faculties as $f)
                                <option value="{{ $f->id }}" @selected(request('faculty_id')==$f->id)>{{ $f->name }}</option>
                            @endforeach
                        </select>
                    </div>
                @endif

                @if($classes->count())
                    <div class="input-icon" style="min-width:200px">
                        <select class="form-control" name="class_id">
                            <option value="">Lớp</option>
                            @foreach($classes as $c)
                                <option value="{{ $c->id }}" @selected(request('class_id')==$c->id)>{{ $c->name }}</option>
                            @endforeach
                        </select>
                    </div>
                @else
                    <div class="input-icon" style="min-width:200px">
                        <input class="form-control" name="class_name" value="{{ request('class_name') }}" placeholder="Lớp (text)">
                    </div>
                @endif
            </div>

            <div class="toolbar-right">
                <a class="btn btn-outline" href="{{ route('admin.students.index') }}">Reset</a>
                <button class="btn btn-brand">Tìm</button>
            </div>
        </form>
    @endcomponent

    <div class="card table">
        <table>
            <thead>
            <tr>
                <th>MSSV</th><th>Họ tên</th><th>Email</th><th>SĐT</th><th>Lớp</th><th>Khoa</th><th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @foreach($students as $st)
                <tr>
                    <td>{{ $st->student_code }}</td>
                    <td>{{ $st->user->name ?? '' }}</td>
                    <td>{{ $st->user->email ?? '' }}</td>
                    <td>{{ $st->user->phone ?? '' }}</td> {{-- <= SĐT cạnh email --}}
                    <td>{{ $st->studentClass->name ?? '—' }}</td>
                    <td>{{ $st->studentClass->major->faculty->name ?? '—' }}</td>
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

        {{ $students->onEachSide(1)->withQueryString()->links() }}
    </div>
@endsection
