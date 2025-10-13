<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <title>Admin Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:#f6f7fb;margin:0}
        .box{max-width:360px;margin:10vh auto;background:#fff;border-radius:12px;padding:24px;box-shadow:0 10px 30px rgba(0,0,0,.06)}
        h1{font-size:20px;margin:0 0 16px}
        label{display:block;font-size:13px;margin:10px 0 6px}
        input[type=email],input[type=password]{width:100%;padding:10px 12px;border:1px solid #e2e8f0;border-radius:8px;font-size:14px}
        .btn{width:100%;padding:12px 14px;border:0;border-radius:10px;background:#111827;color:#fff;font-weight:600;margin-top:16px;cursor:pointer}
        .err{color:#b91c1c;background:#fee2e2;border:1px solid #fecaca;padding:8px;border-radius:8px;margin-bottom:10px;font-size:13px}
    </style>
</head>
<body>
<div class="box">
    <h1>Admin Login</h1>
    @if ($errors->any())
        <div class="err">{{ $errors->first() }}</div>
    @endif
    <form method="POST" action="{{ route('login.post') }}">
        @csrf
        <label>Email</label>
        <input type="email" name="email" value="{{ old('email') }}" required autofocus>
        <label>Mật khẩu</label>
        <input type="password" name="password" required>
        <label style="font-size:13px"><input type="checkbox" name="remember" value="1"> Ghi nhớ</label>
        <button class="btn" type="submit">Đăng nhập</button>
    </form>
</div>
</body>
</html>
