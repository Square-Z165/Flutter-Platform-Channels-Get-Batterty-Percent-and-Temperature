package com.example.source_code

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Tên kênh phải giống hệt tên bên Flutter (main.dart).
    private val batteryChannel = "cosXbatteryChannel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Lắng nghe yêu cầu từ Flutter. call.method là tên yêu cầu Flutter gửi sang,
        // result là nơi gửi câu trả lời về lại cho Flutter.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, batteryChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPercent" -> result.success(getBatteryPercent())
                    "getTemperature" -> {
                        val temperature = getBatteryTemperature()
                        if (temperature != null) {
                            result.success(temperature)
                        } else {
                            result.error("UNAVAILABLE", "Không đọc được nhiệt độ pin", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Hỏi hệ điều hành Android phần trăm pin hiện tại (0-100).
    private fun getBatteryPercent(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    // Android trả nhiệt độ pin theo đơn vị 1/10 độ C (ví dụ 325 nghĩa là 32.5°C),
    // nên phải chia cho 10 trước khi gửi về Flutter.
    private fun getBatteryTemperature(): Double? {
        val batteryInfo = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val tenths = batteryInfo?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1
        return if (tenths == -1) null else tenths / 10.0
    }
}
