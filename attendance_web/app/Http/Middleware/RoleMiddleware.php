<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles)
    {
        $user = $request->user(); // hoạt động cho cả web và api
        if (!$user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }
        if (!empty($roles) && !in_array($user->role, $roles, true)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        return $next($request);
    }
}
