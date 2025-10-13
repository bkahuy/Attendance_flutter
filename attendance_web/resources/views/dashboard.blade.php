<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <title>Điểm danh TLU - Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    {{-- Chart.js CDN --}}
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1"></script>

    <style>
        :root{
            --bg:#f3f4f6; --sidebar:#7c3aed; --sidebar-dark:#6d28d9;
            --card:#fff; --text:#111827; --muted:#6b7280; --border:#e5e7eb;
        }
        *{box-sizing:border-box}
        body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:var(--bg);color:var(--text)}
        .layout{display:grid;grid-template-columns:260px 1fr;min-height:100vh}
        /* Sidebar */
        .side{background:var(--sidebar);color:#fff;display:flex;flex-direction:column}
        .side .brand{display:flex;align-items:center;gap:12px;padding:18px 16px;border-bottom:1px solid rgba(255,255,255,.15)}
        .brand img{width:36px;height:36px;border-radius:50%;background:#fff}
        .brand strong{font-size:16px}
        .menu{padding:12px}
        .menu a{display:flex;align-items:center;gap:12px;color:#fff;text-decoration:none;padding:12px;border-radius:10px;opacity:.95}
        .menu a.active,.menu a:hover{background:var(--sidebar-dark);opacity:1}
        .menu .icon{width:18px;text-align:center}

        /* Main */
        .main{padding:20px 24px}
        .topbar{display:flex;justify-content:flex-end;align-items:center;margin-bottom:16px}
        .avatar{width:28px;height:28px;border-radius:50%;display:inline-block;background:#ddd;margin-left:8px}
        .grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}
        .card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:16px}
        .kpi{font-size:36px;font-weight:800}
        .muted{color:var(--muted);font-size:13px}
        .two{display:grid;grid-template-columns:2fr 1fr;gap:16px;margin-top:16px}
        .toplist ol{margin:8px 0 0 20px;padding:0}
        .toplist li{margin-bottom:6px}
        @media (max-width:1100px){.grid{grid-template-columns:repeat(2,1fr)}.two{grid-template-columns:1fr}}
        @media (max-width:700px){.layout{grid-template-columns:1fr}.side{display:none}}
    </style>
</head>
<body>
<div class="layout">
    <!-- Sidebar -->
    <aside class="side">
        <div class="brand">
            <img src="https://dummyimage.com/72x72/ffffff/7c3aed&text=TLU" alt="logo">
            <div><strong>Điểm danh TLU</strong></div>
        </div>
        <nav class="menu">
            <a href="{{ route('dashboard') }}" class="active"><span class="icon">▦</span>Dashboard</a>
            <a href="#"><span class="icon">👨‍🎓</span>Quản lý sinh viên</a>
            <a href="#"><span class="icon">👨‍🏫</span>Quản lý giảng viên</a>
            <a href="#"><span class="icon">📚</span>Quản lý môn học</a>
            <a href="#"><span class="icon">📆</span>Lịch học</a>
            <a href="#"><span class="icon">📈</span>Báo cáo điểm danh</a>
        </nav>
    </aside>

    <!-- Main -->
    <main class="main">
        <div class="topbar">
            <div>Admin</div>
            <span class="avatar"></span>
            <form method="POST" action="{{ route('logout') }}" style="margin-left:10px">
                @csrf
                <button style="border:0;background:#111827;color:#fff;border-radius:8px;padding:6px 10px;cursor:pointer">Đăng xuất</button>
            </form>
        </div>

        <!-- KPIs -->
        <div class="grid">
            <div class="card">
                <div class="kpi">{{ $studentsCheckedToday }}</div>
                <div class="muted">Số sinh viên đã điểm danh ngày hôm nay</div>
            </div>
            <div class="card">
                <div class="kpi">{{ $classesToday }}</div>
                <div class="muted">Số lớp có lịch học trong ngày hôm nay</div>
            </div>
            <div class="card">
                <div class="kpi">{{ $attendanceRate }}%</div>
                <div class="muted">Tỉ lệ vắng / có mặt</div>
            </div>
            <div class="card toplist">
                <div style="font-weight:700;margin-bottom:6px">Top 3 lớp</div>
                <ol>
                    @forelse($topClasses as $i => $row)
                        <li>{{ $row->course }} ({{ $row->class_section_id }})</li>
                    @empty
                        <li>Chưa có dữ liệu</li>
                    @endforelse
                </ol>
            </div>
        </div>

        <!-- Charts -->
        <div class="two">
            <div class="card">
                <div style="font-weight:700;margin-bottom:6px">Tình trạng điểm danh theo ngày</div>
                <canvas id="barChart" height="140"></canvas>
            </div>
            <div class="card">
                <div style="font-weight:700;margin-bottom:6px">Tỷ lệ điểm danh</div>
                <canvas id="donutChart" height="220"></canvas>
                <div class="muted" style="margin-top:8px">
                    Đúng giờ (present), Muộn (late), Vắng (absent)
                </div>
            </div>
        </div>
    </main>
</div>

<script>
    // Dữ liệu từ PHP
    const BAR_LABELS = @json($barLabels);
    const BAR_VALUES = @json($barValues);
    const DONUT = @json($donut);

    // Bar chart
    new Chart(document.getElementById('barChart'), {
        type: 'bar',
        data: {
            labels: BAR_LABELS,
            datasets: [{
                label: 'Điểm danh (present + late)',
                data: BAR_VALUES,
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            plugins: { legend: { display:false }},
            scales: { y: { beginAtZero:true, ticks:{ precision:0 }}}
        }
    });

    // Doughnut chart
    new Chart(document.getElementById('donutChart'), {
        type: 'doughnut',
        data: {
            labels: ['Đúng giờ','Muộn','Vắng'],
            datasets: [{
                data: [DONUT.present, DONUT.late, DONUT.absent]
            }]
        },
        options: { responsive:true, plugins:{ legend:{ position:'right' }} }
    });
</script>
</body>
</html>
