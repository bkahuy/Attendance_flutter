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
            <div style="margin-top:8px">
                <label>Phòng học</label>
                <input class="form-control" type="text" name="room" placeholder="VD: P201 hoặc Online">
            </div>


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

            {{-- One-shot --}}
            <div id="oneoff" style="margin-top:8px">
                <label>Ngày (one-shot)</label>
                <input class="form-control" type="date" name="date">
            </div>

            {{-- Weekly (multi-days) --}}
            {{-- Weekly (multi-days + optional week range) --}}
            <div id="weekly" style="margin-top:8px;display:none">
                <label>Chọn các thứ (Thứ 2=0 … Chủ nhật=6)</label>
                <div style="display:grid;grid-template-columns:repeat(7,minmax(80px,1fr));gap:8px">
                    @for($i=0;$i<=6;$i++)
                        <label style="display:flex;gap:6px;align-items:center;border:1px solid #e8eaf2;border-radius:8px;padding:6px 8px">
                            <input type="checkbox" name="weekdays[]" value="{{ $i }}">
                            <span>{{ ['T2','T3','T4','T5','T6','T7','CN'][$i] }}</span>
                        </label>
                    @endfor
                </div>

                <div style="margin-top:12px;display:grid;grid-template-columns:1fr 1fr;gap:10px">
                    <div>
                        <label>Từ tuần (chọn 1 ngày trong tuần đầu)</label>
                        <input class="form-control" type="date" name="week_start">
                    </div>
                    <div>
                        <label>Đến tuần (chọn 1 ngày trong tuần cuối)</label>
                        <input class="form-control" type="date" name="week_end">
                    </div>
                </div>
                <div style="margin-top:6px;color:#667085;font-size:13px">
                    • Nếu để trống “Từ/Đến tuần” → tạo lịch lặp vô thời hạn (1 bản ghi/thu).<br>
                    • Nếu chọn “Từ/Đến tuần” → hệ thống sẽ tạo các lịch one-shot cho từng tuần trong khoảng.
                </div>
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
