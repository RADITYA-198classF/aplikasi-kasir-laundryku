<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->string('invoice', 32);
            $table->foreignId('customer_id')->nullable()->constrained('customers')->nullOnDelete();
            // Salinan data pelanggan saat transaksi dibuat, supaya riwayat tidak berubah.
            $table->string('customer_name', 120);
            $table->string('customer_phone', 32)->nullable();
            $table->string('status', 16)->default('antrian'); // antrian | diproses | selesai | diambil
            $table->text('note')->nullable();
            $table->boolean('cancelled')->default(false);
            $table->timestamp('cancelled_at')->nullable();
            $table->foreignId('cancelled_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->unsignedBigInteger('total')->default(0);
            $table->unsignedBigInteger('paid')->default(0);
            $table->dateTime('due_at');
            $table->timestamps();

            $table->unique(['business_id', 'invoice']);
            $table->index(['business_id', 'created_at']);
            $table->index(['business_id', 'status']);
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('service_id')->nullable()->constrained('services')->nullOnDelete();
            // Salinan layanan saat transaksi (harga bisa berubah di kemudian hari).
            $table->string('name', 160);
            $table->string('unit', 8);
            $table->unsignedInteger('price');
            $table->decimal('qty', 10, 2);
            $table->unsignedInteger('duration_hours');
            $table->unsignedBigInteger('subtotal');
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('method', 8); // tunai | qris
            $table->unsignedBigInteger('amount');
            $table->dateTime('paid_at');
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
        });

        Schema::create('order_status_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('status', 16);
            $table->dateTime('logged_at');
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_logs');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
    }
};
