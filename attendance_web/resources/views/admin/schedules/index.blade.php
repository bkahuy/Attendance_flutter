@extends('layouts.app')
@section('title', 'Quản lý thời khoá biểu')

@push('head')
    <style>
        .week-grid{ display:grid; gap:12px; grid-template-columns: repeat(7, minmax(220px,1fr)); }
        .day-col{ background:#fff; border:1px solid #eef1f6; border-radius:12px; padding:12px; }
        .day-title{ font-weight:700; margin-bottom:10px }
        .slot{ border:1px solid #e8eaf2; border-radius:10px; padding:10px; margin-bottom:10px; box-shadow:0 1px 0 #f0f1f6 inset; }
        .slot h4{ margin:0 0 4px; font-size:15px; }
        .slot small{ color:#667085 }
        .slot .actions{ display:flex; gap:8px; margin-top:8px }
    </style>
@endpush

@section('content')
    <div class="section-title"><h2>Quản lý thời khoá biểu</h2></div>

    <form method="get" class="toolbar">
        {{-- “Xem theo: Lớp” --}}
        <div class="pill">
            <span>Xem theo: Lớp</span>
            <select name="class_section_id" onchange="this.form.submit()" style="border:none;outline:none;background:transparent">
                <option value="">Tất cả</option>
                @foreach(\App\Models\ClassSection::with('course')->orderBy('id')->get() as $cs)
                    <option value="{{ $cs->id }}" @selected(request('class_section_id')==$cs->id)>
                        {{ $cs->id }} — {{ $cs->course->code ?? '' }}
                    </option>
                @endforeach
            </select>
        </div>

        {{-- “Xem theo: Giảng viên” --}}
        <div class="pill">
            <span>Xem theo: Giảng viên</span>
            <select name="teacher_id" onchange="this.form.submit()" style="border:none;outline:none;background:transparent">
                <option value="">Tất cả</option>
                @foreach(\App\Models\Teacher::with('user')->orderBy('id')->get() as $t)
                    <option value="{{ $t->id }}" @selected(request('teacher_id')==$t->id)>{{ $t->user->name }}</option>
                @endforeach
            </select>
        </div>

        {{-- Ngày (điểm mốc tuần) --}}
        <div class="pill">
            <input type="date" name="date" value="{{ request('date', $monday->toDateString()) }}">
        </div>

        <button class="icon-btn" title="Tải tuần"><span>Tìm kiếm</span></button>

        <div class="spacer"></div>
        <a class="btn" href="{{ route('admin.schedules.create') }}">Thêm lịch học</a>
    </form>


    <div class="week-grid">
        @foreach($days as $key => $d)
            <div class="day-col">
                <div class="day-title">{{ $d['date']->format('d/m') }}</div>

                @forelse($d['items'] as $sc)
                    <div class="slot">
                        <h4>{{ $sc->classSection->course->name ?? '—' }}</h4>
                        <small>
                            Phòng: {{ $sc->classSection->room ?? '—' }} •
                            {{ \Carbon\Carbon::parse($sc->start_time)->format('H:i') }}
                            – {{ \Carbon\Carbon::parse($sc->end_time)->format('H:i') }}
                            @if($sc->recurring_flag) • Hàng tuần @endif
                        </small>
                        <div class="actions">
                            <a class="btn btn-outline" href="{{ route('admin.schedules.edit',$sc->id) }}">Sửa</a>
                            <form action="{{ route('admin.schedules.destroy',$sc->id) }}" method="post" onsubmit="return confirm('Xoá lịch này?')">
                                @csrf @method('DELETE')
                                <button class="btn btn-danger">Xoá</button>
                            </form>
                        </div>
                    </div>
                @empty
                    <div style="color:#98a2b3">— Trống —</div>
                @endforelse
            </div>
        @endforeach
    </div>
@endsection
