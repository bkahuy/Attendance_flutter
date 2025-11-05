@extends('layouts.app')
@section('title','Quản lý lớp chính khoá')

@section('content')
    <div class="section-title">
        <h2>Quản lý lớp chính khoá</h2>
        <a class="btn" href="{{ route('admin.classes.create') }}">Thêm lớp</a>
    </div>

    <form method="get" class="toolbar" style="justify-content:space-between; gap:12px; flex-wrap:wrap">
        <div style="display:flex; gap:12px; flex-wrap:wrap; flex:1 1 auto">
            <div class="input-icon" style="min-width:240px">
                <input class="form-control" name="q" value="{{ request('q') }}" placeholder="Tìm theo tên lớp">
            </div>

            <div class="input-icon" style="min-width:220px">
                <select class="form-control" name="major_id">
                    <option value="">— Chuyên ngành —</option>
                    @foreach($majors as $m)
                        <option value="{{ $m->id }}" @selected(request('major_id')==$m->id)>{{ $m->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-icon" style="min-width:220px">
                <select class="form-control" name="faculty_id">
                    <option value="">— Khoa —</option>
                    @foreach($faculties as $f)
                        <option value="{{ $f->id }}" @selected(request('faculty_id')==$f->id)>{{ $f->name }}</option>
                    @endforeach
                </select>
            </div>
        </div>

        <div style="display:flex; gap:10px; align-items:center">
            <a class="btn btn-outline" href="{{ route('admin.classes.index') }}">Reset</a>
            <button class="btn">Lọc</button>
        </div>
    </form>

    <div class="card table">
        <table>
            <thead>
            <tr>
                <th style="width:80px">ID</th>
                <th>Tên lớp</th>
                <th>Chuyên ngành</th>
                <th>Khoa</th>
                <th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @foreach($classes as $c)
                <tr>
                    <td>#{{ $c->id }}</td>
                    <td>{{ $c->name }}</td>
                    <td>{{ $c->major->name ?? '—' }}</td>
                    <td>{{ $c->major->faculty->name ?? '—' }}</td>
                    <td>
                        <a class="btn btn-outline" href="{{ route('admin.classes.edit',$c->id) }}">Sửa</a>
                        <form action="{{ route('admin.classes.destroy',$c->id) }}" method="post" style="display:inline" onsubmit="return confirm('Xoá lớp này?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-danger">Xoá</button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>

        {{ $classes->onEachSide(1)->withQueryString()->links() }}
    </div>
@endsection

