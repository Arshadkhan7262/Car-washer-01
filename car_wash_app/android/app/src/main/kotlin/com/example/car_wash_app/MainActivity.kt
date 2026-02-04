package com.example.car_wash_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.car_wash_app/notifications"
    private val NOTIFICATION_CHANNEL_ID = "booking_status_channel"
    private val NOTIFICATION_CHANNEL_NAME = "Booking Status Updates"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channel for Android 8.0+
        createNotificationChannel()
        
        // Set up method channel for handling notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val data = call.argument<Map<String, Any>>("data")
                    
                    if (title != null && body != null) {
                        showNotification(title, body, data)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Title and body are required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle notification data from intent (when app is opened from notification)
        handleNotificationIntent(intent.extras)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for booking status updates"
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(title: String, body: String, data: Map<String, Any>?) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val notificationBuilder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
        
        // Add data payload to notification
        data?.let {
            // Store data in notification extras for Flutter to access
            val bundle = Bundle()
            it.forEach { (key, value) ->
                when (value) {
                    is String -> bundle.putString(key, value)
                    is Int -> bundle.putInt(key, value)
                    is Boolean -> bundle.putBoolean(key, value)
                    is Double -> bundle.putDouble(key, value)
                }
            }
            notificationBuilder.setExtras(bundle)
        }
        
        // Generate unique notification ID
        val notificationId = System.currentTimeMillis().toInt()
        notificationManager.notify(notificationId, notificationBuilder.build())
    }

    private fun handleNotificationIntent(extras: Bundle?) {
        extras?.let {
            // Extract notification data and send to Flutter
            val dataMap = mutableMapOf<String, Any>()
            it.keySet().forEach { key ->
                val value = it.get(key)
                when (value) {
                    is String -> dataMap[key] = value
                    is Int -> dataMap[key] = value
                    is Boolean -> dataMap[key] = value
                    is Double -> dataMap[key] = value
                }
            }
            
            // Send data to Flutter via method channel
            if (dataMap.isNotEmpty()) {
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "onNotificationClicked",
                        dataMap
                    )
                }
            }
        }
    }
}
