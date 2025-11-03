@extends('layouts.app')
@section('title','Báo cáo điểm danh')

@section('content')
    <div class="section-title">
        <h2>Báo cáo điểm danh</h2>
        <form class="d-flex" method="get" style="gap:8px">
            <input class="form-control" type="date" name="date_from" value="{{ request('date_from') }}">
            <input class="form-control" type="date" name="date_to"   value="{{ request('date_to') }}">
            <button class="btn">Lọc</button>
            <a class="btn btn-outline" href="{{ route('reports.attendance.export', request()->query()) }}">Xuất CSV</a>
        </form>
    </div>

    @component('components.card')
        <div style="display:flex;gap:16px;margin-bottom:12px">
            <div class="stat">Tỷ lệ chuyên cần: <b>{{ $rate }}%</b></div>
            <div class="stat">Có mặt: <b>{{ $present }}</b></div>
            <div class="stat">Muộn: <b>{{ $late }}</b></div>
            <div class="stat">Vắng: <b>{{ $absent }}</b></div>
            <div class="stat">Tổng bản ghi: <b>{{ $total }}</b></div>
        </div>

        <div class="table">
            <table>
                <thead>
                <tr>
                    <th>Ngày</th><th>Mã SV</th><th>Họ tên</th><th>Môn</th><th>LHP</th>
                    <th>Trạng thái</th><th>Thời điểm ghi</th>
                </tr>
                </thead>
                <tbody>
                @forelse($rows as $r)
                    <tr>
                        <td>{{ $r->date }}</td>
                        <td>{{ $r->student_code }}</td>
                        <td>{{ $r->student_name }}</td>
                        <td>{{ $r->course_code }} - {{ $r->course_name }}</td>
                        <td>{{ $r->class_section_id }}</td>
                        <td>
                            @if($r->status==='present') <span class="badge success">Đúng giờ</span>
                            @elseif($r->status==='late') <span class="badge warn">Muộn</span>
                            @else <span class="badge danger">Vắng</span>
                            @endif
                        </td>
                        <td>{{ $r->created_at }}</td>
                    </tr>
                @empty
                    <tr><td colspan="7" style="text-align:center;color:#888">Chưa có dữ liệu</td></tr>
                @endforelse
                </tbody>
            </table>
            <div style="margin-top:10px">{{ $rows->links() }}</div>
        </div>
    @endcomponent
@endsection
