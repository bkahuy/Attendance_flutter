@php
    $items = [
      ['href'=>route('dashboard'),                      'label'=>'Dashboard',        'icon'=>'🏠'],

      // Đổi link sang Web Controllers
      ['href'=>route('admin.students.index'),           'label'=>'Quản lý sinh viên', 'icon'=>'🎓'],
      ['href'=>route('admin.teachers.index'),           'label'=>'Quản lý giảng viên','icon'=>'👨‍🏫'],

      // Resource “admin/*” => tên route “admin.*.*”
      ['href'=>route('admin.courses.index'),            'label'=>'Quản lý môn học',   'icon'=>'📚'],
      ['href'=>route('admin.class-sections.index'),     'label'=>'Lớp học phần',      'icon'=>'🏫'],
      ['href'=>route('admin.schedules.index'),          'label'=>'Lịch học',          'icon'=>'📅'],

      // Báo cáo
      ['href'=>route('reports.attendance'),             'label'=>'Báo cáo điểm danh', 'icon'=>'📊'],
    ];
@endphp

<aside class="sidebar">
    <div class="brand">
        <div class="logo">TLU</div>
        <div>
            <h1>Điểm danh TLU</h1>
            <small>Hệ thống quản trị</small>
        </div>
    </div>
    <nav class="nav">
        @foreach($items as $it)
            <a href="{{ $it['href'] ?? '#' }}">
                <span>{{ $it['icon'] }}</span>
                <span>{{ $it['label'] }}</span>
            </a>
        @endforeach

        <form action="{{ route('logout') }}" method="POST" style="margin-top:12px">
            @csrf
            <button type="submit" style="all:unset;display:block;width:100%">
                <span style="display:flex;gap:10px;padding:10px 12px;border-radius:10px;background:#fff;color:#6E6AE8;font-weight:700;cursor:pointer">
                    <span>Đăng xuất</span>
                </span>
            </button>
        </form>
    </nav>
</aside>
