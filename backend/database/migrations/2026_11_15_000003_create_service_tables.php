<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('service_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->string('name', 100);
            $table->string('flow', 150)->default('Cuci -> Pengeringan');
            $table->timestamps();
        });

        Schema::create('services', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('service_category_id')->constrained('service_categories')->restrictOnDelete();
            $table->string('name', 100);
            $table->string('unit', 8);                       // kg | pcs | m2
            $table->unsignedInteger('price');                // rupiah per unit
            $table->decimal('min_qty', 10, 2)->default(0);
            $table->unsignedSmallInteger('duration_value');
            $table->string('duration_unit', 8);              // hari | jam
            $table->boolean('active')->default(true);
            $table->timestamps();

            $table->index('business_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('services');
        Schema::dropIfExists('service_categories');
    }
};
