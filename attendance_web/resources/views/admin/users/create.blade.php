<?php
@extends('layouts.app')
@section('content')
    <div class="card"><div class="card-body">
            <h5 class="mb-3">Tạo User</h5>
            <form method="POST" action="{{ route('users.store') }}">
                @csrf
                <div class="row g-3">
                    <div class="col-md-6"><label class="form-label">Name</label><input name="name" class="form-control" required></div>
                    <div class="col-md-6"><label class="form-label">Email</label><input name="email" type="email" class="form-control" required></div>
                    <div class="col-md-4">
                        <label class="form-label">Role</label>
                        <select name="role" class="form-select" required>
                            <option value="admin">admin</option>
                            <option value="teacher">teacher</option>
                            <option value="student">student</option>
                        </select>
                    </div>
                    <div class="col-md-4"><label class="form-label">Phone</label><input name="phone" class="form-control"></div>
                    <div class="col-md-4">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-select">
                            <option value="active">active</option>
                            <option value="inactive">inactive</option>
                            <option value="blocked">blocked</option>
                        </select>
                    </div>
                    <div class="col-md-6"><label class="form-label">Password (optional)</label><input name="password" type="password" class="form-control"></div>
                </div>
                <div class="mt-3"><button class="btn btn-primary">Lưu</button></div>
            </form>
        </div></div>
@endsection
