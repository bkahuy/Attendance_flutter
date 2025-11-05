@extends('layouts.app')
@section('title','Quản lý môn học')

@section('content')
    <div class="section-title">
        <h2>Quản lý môn học</h2>
        <a class="btn" href="{{ route('admin.courses.create') }}">Thêm môn học</a>
    </div>

    @component('components.card')
        <form method="get" class="toolbar split">
            <div class="toolbar-left">
                <div class="input-icon" style="min-width:220px">
                    <input class="form-control" name="q" value="{{ request('q') }}" placeholder="Tìm mã/tên môn">
                </div>

                <div class="input-icon" style="min-width:220px">
                    <select class="form-control" name="department_id">
                        <option value="">Bộ môn</option>
                        @foreach($departments ?? [] as $d)
                            <option value="{{ $d->id }}" @selected(request('department_id')==$d->id)>{{ $d->name }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="toolbar-right">
                <a class="btn btn-outline" href="{{ route('admin.courses.index') }}">Reset</a>
                <button class="btn btn-brand">Lọc</button>
            </div>
        </form>
    @endcomponent

    @component('components.card')
        <table class="table">
            <thead>
            <tr>
                <th>Mã</th><th>Tên môn</th><th>Tín chỉ</th><th>Bộ môn</th><th style="width:160px">Hành động</th>
            </tr>
            </thead>
            <tbody>
            @foreach($courses as $c)
                <tr>
                    <td>{{ $c->code }}</td>
                    <td>{{ $c->name }}</td>
                    <td>{{ $c->credits }}</td>
                    <td>{{ $c->department->name ?? '' }}</td>
                    <td>
                        <a class="btn btn-outline" href="{{ route('admin.courses.edit',$c->id) }}">Sửa</a>
                        <form action="{{ route('admin.courses.destroy',$c->id) }}" method="post" style="display:inline" onsubmit="return confirm('Xoá?')">
                            @csrf @method('DELETE')
                            <button class="btn btn-danger">Xoá</button>
                        </form>
                    </td>
                </tr>
            @endforeach
            </tbody>
        </table>
        {{ $courses->onEachSide(1)->withQueryString()->links() }}
    @endcomponent
@endsection
