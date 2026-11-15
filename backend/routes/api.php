<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BusinessController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ServiceController;
use App\Http\Middleware\CheckPermission;
use App\Http\Middleware\ForceJsonResponse;
use App\Http\Middleware\OwnerOnly;
use App\Support\Permissions as P;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API LaundryKu  (prefix otomatis /api)
|--------------------------------------------------------------------------
| Hak akses:
|  - owner          : semua fitur
|  - karyawan       : sesuai izin yang diberikan owner (transaksi, batalBayar, layanan, pengeluaran, laporan)
|  - semua akun     : dashboard, pelanggan, melihat layanan/transaksi, ganti password sendiri
*/

Route::middleware([ForceJsonResponse::class])->group(function () {
    Route::get('/health', fn () => response()->json(['status' => 'ok']));

    // ------------------------------------------------------------ auth (publik)
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');

    Route::middleware('auth:sanctum')->group(function () {
        // -------------------------------------------------------- auth (login)
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::put('/auth/password', [AuthController::class, 'changePassword']);

        // -------------------------------------------------------- dashboard
        Route::get('/dashboard', [DashboardController::class, 'index']);

        // -------------------------------------------------------- profil usaha
        Route::get('/business', [BusinessController::class, 'show']);
        Route::put('/business', [BusinessController::class, 'update'])->middleware(OwnerOnly::class);

        // -------------------------------------------------------- karyawan (owner)
        Route::middleware(OwnerOnly::class)->group(function () {
            Route::get('/employees', [EmployeeController::class, 'index']);
            Route::post('/employees', [EmployeeController::class, 'store']);
            Route::put('/employees/{id}', [EmployeeController::class, 'update']);
            Route::delete('/employees/{id}', [EmployeeController::class, 'destroy']);
            Route::put('/employees/{id}/password', [EmployeeController::class, 'resetPassword']);

            Route::post('/categories', [CategoryController::class, 'store']);
            Route::put('/categories/{id}', [CategoryController::class, 'update']);
            Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

            Route::post('/services', [ServiceController::class, 'store']);
            Route::delete('/services/{id}', [ServiceController::class, 'destroy']);
        });

        // -------------------------------------------------------- kategori & layanan
        Route::get('/categories', [CategoryController::class, 'index']);
        Route::get('/services', [ServiceController::class, 'index']);
        // PUT: owner bebas; karyawan dengan hak "layanan" hanya boleh mengubah field `active` (dicek di controller).
        Route::put('/services/{id}', [ServiceController::class, 'update']);
        Route::patch('/services/{id}/active', [ServiceController::class, 'toggle'])
            ->middleware(CheckPermission::class . ':' . P::LAYANAN);

        // -------------------------------------------------------- pelanggan
        Route::get('/customers', [CustomerController::class, 'index']);
        Route::post('/customers', [CustomerController::class, 'store']);
        Route::put('/customers/{id}', [CustomerController::class, 'update']);
        Route::delete('/customers/{id}', [CustomerController::class, 'destroy']);

        // -------------------------------------------------------- transaksi
        Route::get('/orders', [OrderController::class, 'index']);
        Route::get('/orders/{id}', [OrderController::class, 'show']);
        Route::get('/orders/{id}/whatsapp', [OrderController::class, 'whatsapp']);

        Route::middleware(CheckPermission::class . ':' . P::TRANSAKSI)->group(function () {
            Route::post('/orders', [OrderController::class, 'store']);
            Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);
            Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
            Route::post('/orders/{id}/payments', [OrderController::class, 'addPayment']);
        });

        // -------------------------------------------------------- pengeluaran
        // GET terbuka untuk semua akun (aplikasi memuatnya saat login); isinya kosong jika tak punya hak.
        Route::get('/expenses', [ExpenseController::class, 'index']);
        Route::middleware(CheckPermission::class . ':' . P::PENGELUARAN)->group(function () {
            Route::post('/expenses', [ExpenseController::class, 'store']);
            Route::put('/expenses/{id}', [ExpenseController::class, 'update']);
            Route::delete('/expenses/{id}', [ExpenseController::class, 'destroy']);
        });

        // -------------------------------------------------------- laporan
        Route::get('/reports/summary', [ReportController::class, 'summary'])
            ->middleware(CheckPermission::class . ':' . P::LAPORAN);
    });
});
