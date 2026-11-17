package com.example.source_code

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.sqlite.SQLiteDatabase
import android.os.BatteryManager
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

object BatteryHistoryDb {
    const val NAME = "battery_history.db"

    private const val CREATE_TABLE =
        "CREATE TABLE IF NOT EXISTS measurements (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "measured_at INTEGER NOT NULL, " +
            "temperature REAL NOT NULL)"

    fun insert(context: Context, temperature: Double, measuredAt: Long = System.currentTimeMillis()) {
        val file = context.getDatabasePath(NAME)
        file.parentFile?.mkdirs()
        SQLiteDatabase.openOrCreateDatabase(file, null).use { db ->
            db.execSQL(CREATE_TABLE)
            db.execSQL(
                "INSERT INTO measurements (measured_at, temperature) VALUES (?, ?)",
                arrayOf<Any>(measuredAt, temperature),
            )
        }
    }
}

fun readBatteryTemperature(context: Context): Double? {
    val batteryInfo = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    val tenths = batteryInfo?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
    return if (tenths == -1) null else tenths / 10.0
}

class BatteryTemperatureWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    override fun doWork(): Result {
        val temperature = readBatteryTemperature(applicationContext) ?: return Result.success()
        BatteryHistoryDb.insert(applicationContext, temperature)
        return Result.success()
    }
}

object PeriodicMeasurement {
    private const val WORK_NAME = "battery_temperature_every_15_minutes"
    private const val PREFS = "battery_prefs"
    private const val KEY_ENABLED = "periodic_enabled"

    fun start(context: Context) {
        readBatteryTemperature(context)?.let { BatteryHistoryDb.insert(context, it) }

        val request = PeriodicWorkRequestBuilder<BatteryTemperatureWorker>(15, TimeUnit.MINUTES)
            .setInitialDelay(15, TimeUnit.MINUTES)
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request,
        )
        prefs(context).edit().putBoolean(KEY_ENABLED, true).apply()
    }

    fun stop(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        prefs(context).edit().putBoolean(KEY_ENABLED, false).apply()
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
