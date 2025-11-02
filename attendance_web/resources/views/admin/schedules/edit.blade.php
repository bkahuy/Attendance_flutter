@extends('layouts.app')
@section('title','Sửa lịch học')

@section('content')
    <div class="section-title"><h2>Sửa lịch học</h2></div>
    <div class="card" style="max-width:760px">
        <form method="post" action="{{ route('admin.schedules.update',$schedule->id) }}">
            @csrf @method('PUT')

            <label>Lớp học phần</label>
            <select class="form-control" name="class_section_id" required>
                @foreach($classSections as $cs)
                    <option value="{{ $cs->id }}" @selected(old('class_section_id',$schedule->class_section_id)==$cs->id)>
                        {{ $cs->id }} — {{ $cs->course->code ?? '' }} {{ $cs->course->name ?? '' }}
                    </option>
                @endforeach
            </select>

            <div style="margin-top:8px;display:grid;grid-template-columns:1fr 1fr;gap:10px">
                <div>
                    <label>Bắt đầu</label>
                    <input class="form-control" type="time" name="start_time" value="{{ old('start_time', \Carbon\Carbon::parse($schedule->start_time)->format('H:i')) }}" required>
                </div>
                <div>
                    <label>Kết thúc</label>
                    <input class="form-control" type="time" name="end_time" value="{{ old('end_time', \Carbon\Carbon::parse($schedule->end_time)->format('H:i')) }}" required>
                </div>
            </div>

            <div style="margin-top:8px">
                @php $isRecurring = old('recurring_flag', $schedule->recurring_flag) ? true:false; @endphp
                <label><input type="checkbox" name="recurring_flag" value="1" {{ $isRecurring ? 'checked':'' }} onchange="toggleRecurring(this)"> Lặp hàng tuần</label>
            </div>

            <div id="oneoff" style="margin-top:8px; {{ $isRecurring ? 'display:none':'' }}">
                <label>Ngày (one-shot)</label>
                <input class="form-control" type="date" name="date" value="{{ old('date', optional($schedule->date)->format('Y-m-d')) }}">
            </div>

            <div id="weekly" style="margin-top:8px; {{ $isRecurring ? '':'display:none' }}">
                <label>Thứ (WEEKDAY: Thứ 2=0 … Chủ nhật=6)</label>
                <select class="form-control" name="weekday">
                    <option value="">-- Chọn thứ --</option>
                    @for($i=0;$i<=6;$i++)
                        <option value="{{ $i }}" @selected(old('weekday',$schedule->weekday)==$i)>{{ ['T2','T3','T4','T5','T6','T7','CN'][$i] }}</option>
                    @endfor
                </select>
            </div>

            <div style="margin-top:12px;display:flex;gap:10px">
                <a class="btn btn-outline" href="{{ route('admin.schedules.index') }}">Quay lại</a>
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

