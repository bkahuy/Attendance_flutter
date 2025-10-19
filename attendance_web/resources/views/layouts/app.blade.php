<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <title>@yield('title','Dashboard') · Điểm danh TLU</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="/css/admin.css?v={{ now()->format('His') }}">
    <script defer src="/js/admin.js?v={{ now()->format('His') }}"></script>
    @yield('head')
</head>
<body>
<div class="app">
    @include('components.sidebar')
    <main class="main">
        @include('components.topbar')
        <div class="kpis">@yield('kpis')</div>
        <section>@yield('content')</section>
        <div class="footer">© {{ date('Y') }} Điểm danh TLU · Laravel</div>
    </main>
</div>
@yield('scripts')
</body>
</html>
