<div class="topbar">
    <div>
        <div class="breadcrumbs">@yield('breadcrumbs','Dashboard')</div>
        <h2 style="margin:6px 0 0;font-size:18px;font-weight:800">@yield('title','Dashboard')</h2>
    </div>
    <div style="display:flex;align-items:center;gap:12px">
        <div class="search">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
                <path d="M21 21l-4.3-4.3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="2"/>
            </svg>
            <input type="search" placeholder="Tìm nhanh...">
        </div>
        <div style="width:32px;height:32px;border-radius:50%;background:#e5e7eb;display:grid;place-items:center">👤</div>
    </div>
</div>

