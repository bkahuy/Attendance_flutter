@extends('layouts.app')
@section('title','Quản lý lớp học phần')

@section('content')
    <div class="section-title">
        <h2>Quản lý lớp học phần</h2>
        <a class="btn" href="{{ route('admin.class-sections.create') }}">Thêm lớp học phần</a>
    </div>

    @component('components.card')
        <form method="get" class="toolbar split">
            <div class="toolbar-left">
                <div class="input-icon" style="min-width:220px">
                    <select class="form-control" name="course_id">
                        <option value="">— Môn học —</option>
                        @foreach($courses as $c)
                            <option value="{{ $c->id }}" @selected(request('course_id')==$c->id)>
                                {{ $c->code }} — {{ $c->name }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="input-icon" style="min-width:220px">
                    <select class="form-control" name="teacher_id">
                        <option value="">— Giảng viên —</option>
                        @foreach($teachers as $t)
                            <option value="{{ $t->id }}" @selected(request('teacher_id')==$t->id)>
                                {{ $t->user->name ?? 'GV #'.$t->id }}
                            </option>
                        @endforeach
                    </select>
                </div>

                <div class="input-icon" style="min-width:200px">
                    <select class="form-control" name="term">
                        <option value="">— Kỳ học —</option>
                        @foreach($terms as $term)
                            <option value="{{ $term }}" @selected(request('term')==$term)>{{ $term }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="toolbar-right">
                <a class="btn btn-outline" href="{{ route('admin.class-sections.index') }}">Reset</a>
                <button class="btn btn-brand">Lọc</button>
            </div>
        </form>
    @endcomponent

    {{-- Bảng dữ liệu + phân trang --}}
    @component('components.card')
        <table class="table">
            <thead>
            <tr>
                <th>ID</th>
                <th>Môn học</th>
                <th>Giảng viên</th>
                <th>Kỳ</th>
                <th>Phòng</th>
                <th>SL</th>
                <th>Ngày</th>
                <th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @forelse($sections as $s)
                <tr>
                    <td>#{{ $s->id }}</td>
                    <td>{{ $s->course->code ?? '' }} - {{ $s->course->name ?? '' }}</td>
                    <td>{{ $s->teacher->user->name ?? '' }}</td>
                    <td>{{ $s->term ?? '—' }}</td>
                    <td>{{ $s->room ?? '—' }}</td>
                    <td>{{ $s->capacity ?? '—' }}</td>
                    <td>
                        @if($s->start_date || $s->end_date)
                            {{ $s->start_date ?? '—' }} → {{ $s->end_date ?? '—' }}
                        @else
                            —
                        @endif
                    </td>
                    <td>
                        <a class="btn btn-outline" href="{{ route('admin.class-sections.edit',$s->id) }}">Sửa</a>
                        <form action="{{ route('admin.class-sections.destroy',$s->id) }}" method="post" style="display:inline" onsubmit="return confirm('Xoá?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-danger">Xoá</button>
                        </form>
                    </td>
                </tr>
            @empty
                <tr><td colspan="8" style="text-align:center">Chưa có lớp học phần</td></tr>
            @endforelse
            </tbody>
        </table>

        {{-- phân trang giống trang SV/GV; Previous/Next xuất hiện khi >1 trang --}}
        {{ $sections->links() }}
    @endcomponent
@endsection
