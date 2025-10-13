<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <title>@yield('title','Dashboard')</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        :root{--bg:#f6f7fb;--card:#fff;--text:#111827;--muted:#6b7280;--brand:#111827;--chip:#e5e7eb}
        body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:var(--bg);margin:0;color:var(--text)}
        header{background:var(--brand);color:#fff;padding:14px 16px;display:flex;justify-content:space-between;align-items:center}
        main{max-width:1100px;margin:24px auto;background:var(--card);border-radius:12px;padding:24px;box-shadow:0 10px 30px rgba(0,0,0,.06)}
        .chip{display:inline-block;background:var(--chip);border-radius:999px;padding:4px 10px;font-size:12px;margin-left:8px}
        .row{display:flex;gap:16px;flex-wrap:wrap}
        .card{flex:1 1 320px;border:1px solid #e5e7eb;border-radius:12px;padding:16px}
        button{padding:8px 12px;border:0;border-radius:8px;background:#111827;color:#fff;cursor:pointer}
        a.btn{display:inline-block;text-decoration:none;padding:8px 12px;border-radius:8px;background:#111827;color:#fff}
        table{width:100%;border-collapse:collapse}
        th,td{border-bottom:1px solid #e5e7eb;padding:8px;text-align:left;font-size:14px}
    </style>
</head>
<body>
<header>
    <div><strong>Attendance Admin</strong></div>
    <div>
        @auth('web')
            {{ auth('web')->user()->name }}
            <span class="chip">{{ auth('web')->user()->role }}</span>
            <form method="POST" action="{{ route('logout') }}" style="display:inline;margin-left:10px">
                @csrf
                <button type="submit">Đăng xuất</button>
            </form>
        @endauth
    </div>
</header>
<main>
    @yield('content')
</main>
</body>
</html>
