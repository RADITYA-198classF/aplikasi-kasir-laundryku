<?php

// Hanya menimpa zona waktu; sisa konfigurasi app memakai bawaan framework.
// Tanpa file ini, APP_TIMEZONE di .env DIABAIKAN (framework memakai UTC).
return [
    'timezone' => env('APP_TIMEZONE', 'Asia/Jakarta'),
];
