<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Attendance Admin' }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background:#f6f7fb; }
        .navbar-brand { font-weight:700; }
        .card { border:0; box-shadow:0 6px 20px rgba(0,0,0,.05); }
    </style>
</head>
<body>
<nav class="navbar navbar-expand-lg bg-white shadow-sm">
    <div class="container">
        <a class="navbar-brand" href="{{ route('dashboard') }}">Attendance Admin</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#topnav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div id="topnav" class="collapse navbar-collapse">
            <ul class="navbar-nav me-auto">
                <li class="nav-item"><a class="nav-link" href="{{ route('users.index') }}">Users</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('courses.index') }}">Courses</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('class-sections.index') }}">Class Sections</a></li>
            </ul>
            <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button class="btn btn-outline-danger btn-sm">Đăng xuất</button>
            </form>
        </div>
    </div>
</nav>

<main class="container my-4">
    @if(session('ok'))
        <div class="alert alert-success">{{ session('ok') }}</div>
    @endif
    @if($errors->any())
        <div class="alert alert-danger">
            <ul class="mb-0">
                @foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach
            </ul>
        </div>
    @endif

    @yield('content')
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
