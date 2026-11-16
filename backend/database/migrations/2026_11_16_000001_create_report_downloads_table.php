<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Riwayat unduhan laporan (siapa, kapan, periode apa, isi apa yang dipilih). */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_downloads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('user_name', 120)->nullable();   // salinan nama, tetap terbaca walau akun dihapus
            $table->string('format', 8)->default('pdf');
            $table->string('period_label', 60);             // mis. "7 Hari Terakhir"
            $table->date('period_from');
            $table->date('period_to');
            $table->json('sections');                       // isi laporan yang dipilih
            $table->dateTime('downloaded_at');              // waktu unduh (jam server)

            $table->index(['business_id', 'downloaded_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_downloads');
    }
};
