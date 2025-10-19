@extends('layouts.app')
@section('title','Quản lý sinh viên')
@section('breadcrumbs','Quản lý sinh viên')

@section('content')
    <div class="card" style="margin-bottom:12px">
        <div style="display:flex;gap:10px;align-items:center">
            <input class="input" placeholder="Tìm kiếm theo tên / MSSV" style="flex:1">
            <select class="input" style="width:160px"><option>Lớp</option></select>
            <select class="input" style="width:160px"><option>Trạng thái</option></select>
        </div>
    </div>

    @component('components.table', ['headers'=>['Mã SV','Họ tên','Lớp','Trạng thái','']])
        @foreach(($students ?? []) as $s)
            <tr>
                <td>{{ $s->code }}</td>
                <td>{{ $s->user->name ?? '' }}</td>
                <td>{{ $s->class_name ?? '' }}</td>
                <td>
                    @php $st = $s->status ?? 'present'; @endphp
                    <span class="badge {{ $st=='present'?'green':($st=='late'?'orange':'red') }}">
            {{ $st=='present'?'Có mặt':($st=='late'?'Muộn':'Vắng') }}
          </span>
                </td>
                <td class="actions">
                    <a class="icon-btn">✏️</a>
                    <a class="icon-btn">🗑️</a>
                </td>
            </tr>
        @endforeach
    @endcomponent
@endsection

