<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',   // otomatis berawalan /api
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Middleware API (throttle, auth:sanctum, OwnerOnly, CheckPermission) dipasang langsung di routes/api.php.
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Semua error di /api/* (401, 403, 404, 422, 500) dijawab JSON, bukan halaman HTML / redirect.
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request, Throwable $e) => $request->is('api/*') || $request->expectsJson()
        );
    })->create();
