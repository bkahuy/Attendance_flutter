<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title','Admin')</title>
    <style>
        :root { --brand:#8986F4; }
        body { font-family: ui-sans-serif,system-ui,Segoe UI,Roboto; background:#f5f7fb; margin:0; color:#111; }

        .wrap { display:grid; grid-template-columns: 220px 1fr; min-height:100vh; }
        .side { background:linear-gradient(180deg,var(--brand),#7e7af0); padding:18px; color:#fff; }
        .side h1 { font-size:18px; margin:0 0 12px }
        .side a { display:block; padding:8px 10px; border-radius:8px; color:#fff; text-decoration:none; margin-bottom:6px }
        .side a:hover { background:rgba(255,255,255,.15) }

        .main { padding:22px; width:100%; max-width:none; } /* bè ngang hết */

        .section-title { display:flex; align-items:center; justify-content:space-between; margin-bottom:12px }
        .btn { background:var(--brand); color:#fff; border:none; padding:8px 12px; border-radius:8px; cursor:pointer; }
        .btn-outline { background:#fff; color:#333; border:1px solid #e5e7eb; }
        .btn-danger { background:#e5484d; color:#fff; }
        .form-control { width:100%; padding:8px 10px; border:1px solid #e5e7eb; border-radius:8px; }

        /* Card + table */
        .card { background:#fff; border:1px solid #eef1f6; border-radius:12px; padding:14px; margin-bottom:14px }
        .table { width:100% }
        .table table { width:100%; border-collapse:collapse; background:#fff; table-layout:fixed; } /* căng đều cột */
        .table th,.table td { padding:10px; border-bottom:1px solid #eef1f6; text-align:left; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }

        /* Pagination: đừng phóng to dấu « » */
        main nav[role="navigation"] a,
        main nav[role="navigation"] span {
            font-size:14px; line-height:1.2; display:inline-flex; padding:6px 10px;
            border-radius:8px; border:1px solid #e5e7eb; background:#fff; color:#111;
        }
        main nav[role="navigation"] .hidden { display:none; }
        /* === Toolbar (giống mockup) === */
        .toolbar{
            display:flex; align-items:center; gap:12px; flex-wrap:wrap;
        }
        .toolbar .spacer{ flex:1 }                 /* đẩy nút “Thêm …” sang phải */

        .input-icon{ position:relative; min-width:260px }
        .input-icon input,.input-icon select{
            width:100%; padding:10px 12px 10px 38px; border:1px solid #e5e7eb;
            border-radius:10px; background:#fff; outline:none;
        }
        .input-icon .ico{
            position:absolute; left:10px; top:50%; transform:translateY(-50%);
            font-size:16px; opacity:.55;
        }

        .pill{
            padding:8px 12px; border:1px solid #e5e7eb; border-radius:10px; background:#fff; color:#444;
            display:inline-flex; align-items:center; gap:8px; min-height:40px;
        }
        .pill input[type="date"]{ border:none; outline:none; background:transparent; padding:0 4px }

        .icon-btn{
            display:inline-flex; align-items:center; justify-content:center;
            width:48px; height:40px; border-radius:10px; background:#e6e7eb; border:1px solid #e5e7eb;
        }
        .icon-btn:hover{ filter:brightness(.97) }

        .btn, .btn-outline{ text-decoration:none } /* dẹp gạch chân */

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
    </main>
</div>
@stack('scripts')
</body>
</html>
