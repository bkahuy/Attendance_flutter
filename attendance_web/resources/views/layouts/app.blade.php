<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title','Admin')</title>
    <style>
        :root {
            --brand:#8986F4;
            --top-offset: 140px;
        }
        * { box-sizing:border-box; margin:0; padding:0; }
        html,body { width:100%; height:100%; overflow-x:hidden; }
        body {
            font-family: ui-sans-serif, system-ui, Segoe UI, Roboto;
            background:#f5f7fb;
            color:#111;
        }

        /* === GRID CHÍNH === */
        .wrap{
            display:grid;
            grid-template-columns:220px minmax(0,1fr);
            min-height:100vh;
        }

        /* === SIDEBAR === */
        .side{
            background:linear-gradient(180deg, var(--brand), #7e7af0);
            color:#fff;
            padding:18px;
            position:sticky; top:0;
            height:100vh; overflow-y:auto;
        }
        .side h1{ font-size:18px; margin-bottom:12px; }
        .side a{ display:block; padding:8px 10px; color:#fff; text-decoration:none; border-radius:8px; margin-bottom:6px; }
        .side a:hover{ background:rgba(255,255,255,.15); }

        /* === MAIN === */
        .main{
            padding:22px;
            width:100%;
            max-width:1280px;
            margin:0 auto;
        }
        .section-title{ display:flex; align-items:center; justify-content:space-between; margin-bottom:12px; }

        /* === BUTTON === */
        .btn{
            background:var(--brand); color:#fff; border:none;
            padding:10px 14px; border-radius:8px; cursor:pointer;
            display:inline-flex; align-items:center; gap:6px; text-decoration:none;
        }
        .btn-outline{
            background:#fff; color:#333; border:1px solid #e5e7eb;
            padding:8px 12px; border-radius:8px;
        }
        .btn-danger{ background:#e5484d; color:#fff; border:none; padding:8px 12px; border-radius:8px; }

        /* === TOOLBAR / FORM === */
        .toolbar.split{ display:flex; flex-wrap:wrap; align-items:center; gap:12px; }
        .toolbar-left{ display:flex; flex-wrap:wrap; gap:12px; }
        .toolbar-right{ margin-left:auto; display:flex; gap:10px; }

        .input-icon{ flex:1 1 220px; max-width:340px; }
        .input-icon input,.input-icon select{
            width:100%; padding:10px; border:1px solid #e5e7eb;
            border-radius:10px; background:#fff; outline:none;
        }

        /* === CARD & TABLE === */
        .card{
            background:#fff; border:1px solid #eef1f6; border-radius:12px;
            padding:14px; margin-bottom:14px;
        }
        .table{ width:100%; overflow-x:auto; }
        .table table{ width:100%; border-collapse:collapse; }
        .table th,.table td{ padding:10px; border-bottom:1px solid #eef1f6; }

        /* === LỊCH TUẦN === */
        .week-wrap{
            overflow-x:auto;
            padding-bottom:8px;
        }
        .week-grid{
            display:grid;
            grid-template-columns: repeat(7, minmax(220px, 1fr));
            min-width:1200px;
            gap:16px;
            align-items:start;
        }
        .day-col{
            height:calc(100vh - var(--top-offset));
            background:#fff;
            border:1px solid #eef1f6;
            border-radius:12px;
            display:flex;
            flex-direction:column;
            overflow:hidden;
        }
        .day-head{
            position:sticky; top:0;
            background:#fff;
            padding:12px;
            border-bottom:1px dashed #e9edf4;
            font-weight:700;
        }
        .day-body{
            flex:1;
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
        .slot h4{ font-size:15px; margin:0 0 4px; line-height:1.35; white-space:normal; word-break:break-word; }
        .slot small{ color:#667085; }
        /* === FORM BASELINE (fix create/edit bị trơ) === */
        .card form > div{ display:grid; gap:6px; }

        label{
            font-size:14px; font-weight:600; color:#374151;
        }

        .form-control{
            width:100%;
            padding:10px 12px;
            border:1px solid #e5e7eb;
            border-radius:10px;
            background:#fff;
            outline:none;
            transition:border-color .15s ease, box-shadow .15s ease;
        }

        .form-control:focus{
            border-color: var(--brand);
            box-shadow:0 0 0 3px rgba(137,134,244,.15);
        }

        /* input disabled hiển thị nhẹ màu */
        .form-control:disabled{
            background:#f8fafc; color:#6b7280;
        }

        /* khoảng cách button ở cuối form */
        .card form .btn{ margin-top:4px; }

        /* thông báo chung (flash) dùng ở layout */
        .flash{
            background:#eff6ff; color:#1e40af;
            border:1px solid #bfdbfe;
            padding:10px 12px; border-radius:8px; margin-bottom:12px;
        }

        /* giữ style đồng bộ cho select/textarea nếu có */
        select.form-control, textarea.form-control{
            -webkit-appearance:none; -moz-appearance:none; appearance:none;
        }

        /* Responsive nhẹ cho cột form dài */
        @media (max-width: 640px){
            .input-icon{ max-width:100%; }
        }

    </style>


    @stack('head')
</head>
<body>
<div class="wrap">
    <aside class="side">
        <h1>Điểm danh TLU</h1>
        <nav>
            <a href="{{ route('dashboard') }}">Dashboard</a>
            <a href="{{ route('admin.students.index') }}">Quản lý sinh viên</a>
            <a href="{{ route('admin.teachers.index') }}">Quản lý giảng viên</a>
            <a href="{{ route('admin.courses.index') }}">Quản lý môn học</a>
            <a href="{{ route('admin.classes.index') }}">Quản lý lớp chính khoá</a>
            <a href="{{ route('admin.class-sections.index') }}">Quản lý lớp học phần</a>
            <a href="{{ route('admin.schedules.index') }}">Thời khoá biểu</a>
            <a href="{{ route('reports.attendance') }}">Báo cáo điểm danh</a>
        </nav>
        <form method="post" action="{{ route('logout') }}" style="margin-top:16px">@csrf
            <button class="btn btn-outline" style="width:100%">Đăng xuất</button>
        </form>
    </aside>

    <main class="main">
        @if(session('ok')) <div class="flash">{{ session('ok') }}</div> @endif
        @yield('content')
            @if ($errors->any())
                <div style="background:#FEE2E2;color:#991B1B;border:1px solid #FCA5A5;padding:10px;border-radius:8px;margin-bottom:12px">
                    <ul style="margin:0;padding-left:18px">
                        @foreach ($errors->all() as $e)
                            <li>{{ $e }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

    </main>
</div>

@stack('scripts')
</body>
</html>
