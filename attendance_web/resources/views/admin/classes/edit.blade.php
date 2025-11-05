@extends('layouts.app')
@section('title','Sửa lớp chính khoá')

@section('content')
    <div class="section-title">
        <h2>Sửa lớp #{{ $class->id }}</h2>
    </div>

    @component('components.card')
        <form method="post" action="{{ route('admin.classes.update',$class->id) }}" style="max-width:600px;display:grid;gap:12px">
            @csrf @method('PUT')

            <div>
                <label>Tên lớp</label>
                <input name="name" class="form-control" value="{{ old('name',$class->name) }}" required>
            </div>

            <div>
                <label>Chuyên ngành</label>
                <select name="major_id" class="form-control" required>
                    @foreach($majors as $m)
                        <option value="{{ $m->id }}" @selected(old('major_id',$class->major_id)==$m->id)>{{ $m->name }}</option>
                    @endforeach
                </select>
            </div>

            <div style="display:flex; gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.classes.index') }}">Quay lại</a>
                <button class="btn">Cập nhật</button>
            </div>
        </form>
    @endcomponent
@endsection
