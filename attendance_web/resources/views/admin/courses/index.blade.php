<?php
@extends('layouts.app')
@section('content')
    <div class="d-flex justify-content-between mb-3">
        <h5 class="mb-0">Courses</h5>
        <a href="{{ route('courses.create') }}" class="btn btn-primary">+ New Course</a>
    </div>
    <div class="card">
        <div class="table-responsive">
            <table class="table table-striped mb-0">
                <thead><tr><th>#</th><th>Code</th><th>Name</th><th>Credits</th><th></th></tr></thead>
                <tbody>
                @foreach($courses as $c)
                    <tr>
                        <td>{{ $c->id }}</td>
                        <td>{{ $c->code }}</td>
                        <td>{{ $c->name }}</td>
                        <td>{{ $c->credits }}</td>
                        <td class="text-end">
                            <a class="btn btn-sm btn-outline-primary" href="{{ route('courses.edit',$c) }}">Sửa</a>
                            <form class="d-inline" method="POST" action="{{ route('courses.destroy',$c) }}" onsubmit="return confirm('Xoá?')">
                                @csrf @method('DELETE') <button class="btn btn-sm btn-outline-danger">Xoá</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
        <div class="card-footer">{{ $courses->links() }}</div>
    </div>
@endsection
