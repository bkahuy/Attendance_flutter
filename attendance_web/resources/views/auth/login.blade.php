<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Đăng nhập – TLU</title>
    <link rel="stylesheet" href="{{ asset('css/login.css') }}">
</head>
<body>
<div class="login-shell">
    <!-- Cột trái: ảnh -->
    <div class="login-hero" style="background-image:url('{{ asset('images/truongtlu.jpg') }}');"></div>

    <!-- Cột phải: nền tím + form -->
    <div class="login-panel">
        <div class="form-wrap">
            <div class="login-logo">
                <img src="{{ asset('images/tlu.webp') }}" alt="TLU" style="width:110px;height:90px;">

            </div>

            <div class="login-title">
                <h1>TLU</h1>
                <p>Trang Quản lý cho Admin</p>
            </div>

            @if ($errors->any())
                <div class="err">
                    @foreach ($errors->all() as $error)
                        <div>{{ $error }}</div>
                    @endforeach
                </div>
            @endif

            <form method="POST" action="{{ route('login') }}">
                @csrf

                <div class="form-group">
                    <label class="label" for="email">Email</label>
                    <input id="email" name="email" type="email" class="input"
                           value="{{ old('email') }}" required autofocus autocomplete="username">
                </div>

                <div class="form-group">
                    <label class="label" for="password">Mật khẩu</label>
                    <input id="password" name="password" type="password" class="input"
                           required autocomplete="current-password">
                </div>

                <div class="row">
                    @if (Route::has('password.request'))
                        <a href="{{ route('password.request') }}" style="color:#fff;text-decoration:underline;">Quên mật khẩu?</a>
                    @endif
                </div>

                <button class="btn" type="submit">ĐĂNG NHẬP</button>
            </form>
        </div>
    </div>
</div>
</body>
</html>
