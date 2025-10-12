<?php
@extends('layouts.app')
@section('content')
    <div class="d-flex justify-content-between align-items-center mb-3">
        <form class="d-flex" method="get">
            <input class="form-control me-2" name="q" placeholder="Tìm tên/email" value="{{ $q }}">
            <button class="btn btn-outline-secondary">Search</button>
        </form>
        <a href="{{ route('users.create') }}" class="btn btn-primary">+ New User</a>
    </div>

    <div class="card">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>Status</th><th></th></tr></thead>
                <tbody>
                @foreach($users as $u)
                    <tr>
                        <td>{{ $u->id }}</td>
                        <td>{{ $u->name }}</td>
                        <td>{{ $u->email }}</td>
                        <td><span class="badge text-bg-info">{{ $u->role }}</span></td>
                        <td><span class="badge text-bg-{{ $u->status=='active'?'success':'secondary' }}">{{ $u->status }}</span></td>
                        <td class="text-end">
                            <a class="btn btn-sm btn-outline-primary" href="{{ route('users.edit',$u) }}">Sửa</a>
                            <form class="d-inline" method="POST" action="{{ route('users.destroy',$u) }}" onsubmit="return confirm('Xoá user này?')">
                                @csrf @method('DELETE')
                                <button class="btn btn-sm btn-outline-danger">Xoá</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
        <div class="card-footer">{{ $users->withQueryString()->links() }}</div>
    </div>
@endsection
