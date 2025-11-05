@extends('layouts.app')
@section('title', 'Quản lý thời khoá biểu')

@php
    /* Gắn class cho <body> chỉ riêng trang lịch, để override width của .main */
    View::share('body_class', 'schedules-page');
@endphp

@push('head')
    <style>
        .wrap > .main {
            max-width: none !important;
            margin: 0 !important;
            width: 100% !important;
            padding: 22px 32px !important;
        }
        :root{
            --brand:#8986F4;
            --top-offset:140px;
        }

        /* MỞ RỘNG RIÊNG TRANG LỊCH: bỏ max-width của .main trong layout */
        body.schedules-page .main{
            max-width: none !important;
            margin: 0 !important;
            padding: 22px 32px !important;
            width: 100% !important;
        }

        .toolbar.split{ display:flex; align-items:center; gap:12px; flex-wrap:wrap; }
        .toolbar .toolbar-left{ display:flex; gap:10px; flex-wrap:wrap; }
        .toolbar .toolbar-right{ margin-left:auto; display:flex; gap:10px; }
        .btn.btn-brand{ background:var(--brand); color:#fff; }

        .filters-sticky{ position:sticky; top:64px; z-index:5; }

        .week-wrap{ overflow-x:auto; padding-bottom:8px; }
        .week-grid{
            display:grid;
            grid-template-columns:repeat(7,1fr);
            min-width:1200px;      /* đủ rộng cho 7 cột, vẫn kéo ngang khi hẹp */
            gap:16px;
            align-items:start;
        }

        .day-col{
            background:#fff;
            border:1px solid #eef1f6;
            border-radius:12px;
            display:flex;
            flex-direction:column;
            height:calc(100vh - var(--top-offset));
            overflow:hidden;
        }

        .day-head{
            position:sticky;
            top:0;
            background:#fff;
            padding:12px;
            border-bottom:1px dashed #e9edf4;
            font-weight:700;
            z-index:1;
        }

        .day-body{
            flex:1;
            padding:12px;
            display:flex;
            flex-direction:column;
            gap:10px;
            overflow-y:auto;
            overscroll-behavior:contain;
            scrollbar-gutter:stable both-edges;
            -webkit-overflow-scrolling:touch;
            scrollbar-width:thin;
            scrollbar-color:#cbd5e1 transparent;
        }

        .day-body::-webkit-scrollbar{ width:8px; }
        .day-body::-webkit-scrollbar-thumb{ background:#cbd5e1; border-radius:8px; }
        .day-body::-webkit-scrollbar-track{ background:transparent; }
        .day-body::-webkit-scrollbar-button{ display:none; }

        .slot{
            border:1px solid #e8eaf2;
            border-radius:10px;
            padding:10px;
            box-shadow:0 1px 0 #f0f1f6 inset;
        }
        .slot h4{
            margin:0 0 4px;
            font-size:15px;
            line-height:1.35;
            white-space:normal;
            word-break:break-word;
        }
        .slot small{ color:#667085; }
    </style>
@endpush

@section('content')
    <div class="section-title">
        <h2>Quản lý thời khoá biểu</h2>
        <a class="btn" href="{{ route('admin.schedules.create') }}">Thêm lịch học</a>
    </div>

    @component('components.card')
        <div class="filters-sticky">
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

                    <div class="input-icon" style="min-width:220px">
                        <select class="form-control" name="class_section_id">
                            <option value="">— Lớp học phần —</option>
                            @foreach(\App\Models\ClassSection::with('course')->orderBy('id')->get() as $cs)
                                <option value="{{ $cs->id }}" @selected(request('class_section_id')==$cs->id)>
                                    {{ $cs->id }} — {{ $cs->course->code ?? '' }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="input-icon" style="min-width:200px">
                        <input class="form-control" type="date" name="date" value="{{ request('date', $monday->toDateString()) }}">
                    </div>
                </div>

                <div class="toolbar-right">
                    <a class="btn btn-outline" href="{{ route('admin.schedules.index') }}">Reset</a>
                    <button class="btn btn-brand">Lọc</button>
                </div>
            </form>
        </div>
    @endcomponent

    <div style="margin:10px 0 16px;color:#667085;display:flex;align-items:center;gap:12px">
        <form method="get" action="{{ route('admin.schedules.index') }}" style="display:inline;">
            <input type="hidden" name="date" value="{{ $monday->copy()->subWeek()->toDateString() }}">
            <button class="btn btn-outline">« Tuần trước</button>
        </form>

        <div style="flex:1;text-align:center">
            Tuần: {{ $monday->format('d/m/Y') }} – {{ $sunday->format('d/m/Y') }}
        </div>

        <form method="get" action="{{ route('admin.schedules.index') }}" style="display:inline;">
            <input type="hidden" name="date" value="{{ $monday->copy()->addWeek()->toDateString() }}">
            <button class="btn btn-outline">Tuần sau »</button>
        </form>
    </div>

    <div class="week-wrap">
        <div class="week-grid">
            @foreach($days as $key => $d)
                <div class="day-col">
                    <div class="day-head">
                        {{ ['T2','T3','T4','T5','T6','T7','CN'][$d['date']->isoWeekday()-1] }} — {{ $d['date']->format('d/m') }}
                    </div>
                    <div class="day-body">
                        @forelse($d['items'] as $sc)
                            <div class="slot">
                                <h4>{{ $sc->classSection->course->name ?? '—' }}</h4>
                                <small>
                                    Lớp: {{ $sc->class_section_id }} •
                                    GV: {{ $sc->classSection->teacher->user->name ?? '—' }} •
                                    Phòng: {{ $sc->room ?? $sc->classSection->room ?? '—' }} •
                                    {{ \Carbon\Carbon::parse($sc->start_time)->format('H:i') }} –
                                    {{ \Carbon\Carbon::parse($sc->end_time)->format('H:i') }}
                                    @if($sc->recurring_flag)
                                        • Lặp tuần
                                    @else
                                        • Ngày: {{ \Carbon\Carbon::parse($sc->date)->format('d/m') }}
                                    @endif
                                </small>

                                <div style="margin-top:6px;display:flex;gap:6px">
                                    <a href="{{ route('admin.schedules.edit',$sc->id) }}" class="btn btn-outline" style="padding:4px 8px;font-size:13px">Sửa</a>
                                    <form method="post" action="{{ route('admin.schedules.destroy',$sc->id) }}" onsubmit="return confirm('Xoá lịch này?')" style="display:inline">
                                        @csrf @method('DELETE')
                                        <button class="btn btn-danger" style="padding:4px 8px;font-size:13px">Xoá</button>
                                    </form>
                                </div>
                            </div>
                        @empty
                            <div style="color:#98a2b3">— Trống —</div>
                        @endforelse
                    </div>
                </div>
            @endforeach
        </div>
    </div>
@endsection

@push('scripts')
    <script>
        (function(){
            const grid=document.querySelector('.week-grid');
            if(!grid)return;
            function recalc(){
                const rect=grid.getBoundingClientRect();
                const offset=Math.max(120,Math.round(rect.top+20));
                document.documentElement.style.setProperty('--top-offset',offset+'px');
            }
            recalc();
            window.addEventListener('resize',recalc);
        })();
    </script>
@endpush
