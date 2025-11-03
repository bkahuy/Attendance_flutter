@extends('layouts.app')
@section('title','Quản lý môn học')
@section('content')
    <div class="section-title">
        <h2>Quản lý môn học</h2>
        <form method="get" style="display:flex;gap:10px;flex-wrap:wrap">
            <input class="form-control" name="search" value="{{ request('search') }}" placeholder="Tìm mã/tên môn">
            <button class="btn">Lọc</button>
            <a class="btn btn-outline" href="{{ route('admin.courses.create') }}">Thêm môn học</a>
        </form>
    </div>
    @component('components.card')
        <table class="table">
            <thead><tr><th>Mã</th><th>Tên môn</th><th>Tín chỉ</th><th>Bộ môn</th><th style="width:160px">Hành động</th></tr></thead>
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
        {{ $courses->links() }}
    @endcomponent
@endsection

