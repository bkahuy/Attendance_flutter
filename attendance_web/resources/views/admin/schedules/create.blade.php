@extends('layouts.app')
@section('title','Thêm lịch học')

@section('content')
    <div class="section-title"><h2>Thêm lịch học</h2></div>
    <div class="card" style="max-width:760px">
        <form method="post" action="{{ route('admin.schedules.store') }}">
            @csrf

            <label>Lớp học phần</label>
            <select class="form-control" name="class_section_id" required>
                @foreach($classSections as $cs)
                    <option value="{{ $cs->id }}">{{ $cs->id }} — {{ $cs->course->code ?? '' }} {{ $cs->course->name ?? '' }}</option>
                @endforeach
            </select>

            <div style="margin-top:8px;display:grid;grid-template-columns:1fr 1fr;gap:10px">
                <div>
                    <label>Bắt đầu</label>
                    <input class="form-control" type="time" name="start_time" required>
                </div>
                <div>
                    <label>Kết thúc</label>
                    <input class="form-control" type="time" name="end_time" required>
                </div>
            </div>

            <div style="margin-top:8px">
                <label><input type="checkbox" name="recurring_flag" value="1" onchange="toggleRecurring(this)"> Lặp hàng tuần</label>
            </div>

            <div id="oneoff" style="margin-top:8px">
                <label>Ngày (one-shot)</label>
                <input class="form-control" type="date" name="date">
            </div>

            <div id="weekly" style="margin-top:8px;display:none">
                <label>Thứ (WEEKDAY: Thứ 2=0 … Chủ nhật=6)</label>
                <select class="form-control" name="weekday">
                    <option value="">-- Chọn thứ --</option>
                    @for($i=0;$i<=6;$i++)
                        <option value="{{ $i }}">{{ ['T2','T3','T4','T5','T6','T7','CN'][$i] }}</option>
                    @endfor
                </select>
            </div>

            <div style="margin-top:12px;display:flex;gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.schedules.index') }}">Huỷ</a>
                <button class="btn">Lưu</button>
            </div>
        </form>
    </div>

    @push('scripts')
        <script>
            function toggleRecurring(cb){
                document.getElementById('weekly').style.display = cb.checked ? 'block':'none';
                document.getElementById('oneoff').style.display = cb.checked ? 'none':'block';
            }
        </script>
    @endpush
@endsection
