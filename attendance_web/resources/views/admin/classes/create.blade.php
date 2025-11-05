@extends('layouts.app')
@section('title','Thêm lớp chính khoá')

@section('content')
    <div class="section-title">
        <h2>Thêm lớp chính khoá</h2>
    </div>

    @component('components.card')
        <form method="post" action="{{ route('admin.classes.store') }}" style="max-width:600px;display:grid;gap:12px">
            @csrf

            <div>
                <label>Tên lớp</label>
                <input name="name" class="form-control" value="{{ old('name') }}" required>
            </div>

            <div>
                <label>Chuyên ngành</label>
                <select name="major_id" class="form-control" required>
                    <option value="">— Chọn chuyên ngành —</option>
                    @foreach($majors as $m)
                        <option value="{{ $m->id }}" @selected(old('major_id')==$m->id)>{{ $m->name }}</option>
                    @endforeach
                </select>
            </div>

            <div style="display:flex; gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.classes.index') }}">Huỷ</a>
                <button class="btn">Lưu</button>
            </div>
        </form>
    @endcomponent
@endsection
