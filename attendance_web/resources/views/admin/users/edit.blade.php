<?php
@extends('layouts.app')
@section('content')
    <div class="card"><div class="card-body">
            <h5 class="mb-3">Sửa User #{{ $user->id }}</h5>
            <form method="POST" action="{{ route('users.update',$user) }}">
                @csrf @method('PUT')
                <div class="row g-3">
                    <div class="col-md-6"><label class="form-label">Name</label><input name="name" class="form-control" value="{{ $user->name }}" required></div>
                    <div class="col-md-6"><label class="form-label">Email</label><input name="email" type="email" class="form-control" value="{{ $user->email }}" required></div>
                    <div class="col-md-4">
                        <label class="form-label">Role</label>
                        <select name="role" class="form-select" required>
                            @foreach(['admin','teacher','student'] as $r)
                                <option value="{{ $r }}" @selected($user->role==$r)>{{ $r }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-4"><label class="form-label">Phone</label><input name="phone" class="form-control" value="{{ $user->phone }}"></div>
                    <div class="col-md-4">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-select">
                            @foreach(['active','inactive','blocked'] as $s)
                                <option value="{{ $s }}" @selected($user->status==$s)>{{ $s }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-6"><label class="form-label">New Password</label><input name="password" type="password" class="form-control"></div>
                </div>
                <div class="mt-3"><button class="btn btn-primary">Cập nhật</button></div>
            </form>
        </div></div>
@endsection
