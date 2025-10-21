<div class="card">
    <table class="table">
        <thead>
        <tr>
            @foreach($headers as $h)
                <th>{{ $h }}</th>
            @endforeach
        </tr>
        </thead>
        <tbody>
        {{ $slot }}
        </tbody>
    </table>
</div>

