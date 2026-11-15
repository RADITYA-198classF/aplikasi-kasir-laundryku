<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('business_id')->nullable()->after('id')->constrained('businesses')->cascadeOnDelete();
            $table->string('role', 16)->default('owner')->after('password'); // owner | employee
            $table->string('phone', 32)->nullable()->after('email');
            $table->json('permissions')->nullable()->after('role');          // hanya dipakai role employee
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('business_id');
            $table->dropColumn(['role', 'phone', 'permissions']);
        });
    }
};
