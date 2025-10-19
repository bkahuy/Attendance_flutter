@extends('layouts.app')
@section('title','Dashboard')
@section('breadcrumbs','Dashboard')

@section('kpis')
    <div class="card">
        <h3>Sinh viên đã điểm danh hôm nay</h3>
        <div class="big">{{ $stats['today_attendances'] ?? 76 }}</div>
        <div class="muted">so với hôm qua: +{{ $stats['today_delta'] ?? 5 }}</div>
    </div>
    <div class="card">
        <h3>Số lớp có lịch học hôm nay</h3>
        <div class="big">{{ $stats['today_classes'] ?? 8 }}</div>
    </div>
    <div class="card">
        <h3>Tỉ lệ vắng / có mặt</h3>
        <div class="big">{{ $stats['presence_rate'] ?? '80%' }}</div>
    </div>
    <div class="card">
        <h3>Top 3 lớp</h3>
        <div class="muted">64KTPM3<br>64KTPM2<br>64KHTT2</div>
    </div>
@endsection

@section('content')
    <div class="section-title">
        <h2>Tình trạng điểm danh theo ngày</h2>
        <a class="btn" href="{{ route('reports.attendance') }}">Xem báo cáo</a>
    </div>
    @component('components.card')
        <div style="height:220px;display:grid;place-items:center;color:var(--muted)">[Biểu đồ cột – gắn chart.js sau]</div>
    @endcomponent

    <div class="section-title">
        <h2>Tỉ lệ điểm danh</h2>
        <span></span>
    </div>
    @component('components.card')
        <div style="height:220px;display:grid;place-items:center;color:var(--muted)">[Biểu đồ donut – gắn chart.js sau]</div>
    @endcomponent
@endsection
