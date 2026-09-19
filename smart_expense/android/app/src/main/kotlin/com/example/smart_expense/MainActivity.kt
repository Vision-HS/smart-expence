package com.example.smart_expense

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.smart_expense/sms_channel"
    private val EVENT_CHANNEL = "com.example.smart_expense/sms_stream"
    private val NOTIF_METHOD_CHANNEL = "com.example.smart_expense/notification_channel"
    private val NOTIF_EVENT_CHANNEL = "com.example.smart_expense/notification_stream"
    private val PERMISSION_REQUEST_CODE = 1010

    private var permissionResultCallback: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var notifEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel for SMS
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkSmsPermissions" -> {
                    val readGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    val receiveGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    result.success(readGranted && receiveGranted)
                }
                "requestSmsPermissions" -> {
                    val readGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    val receiveGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
                    if (readGranted && receiveGranted) {
                        result.success(true)
                    } else {
                        permissionResultCallback = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
                            PERMISSION_REQUEST_CODE
                        )
                    }
                }
                "readInboxSms" -> {
                    val limit = call.argument<Int>("limit") ?: 100
                    val smsList = readInboxMessages(limit)
                    result.success(smsList)
                }
                "getBufferedSms" -> {
                    val buffered = SmsReceiver.getAndClearBufferedMessages(this)
                    result.success(buffered)
                }
                else -> result.notImplemented()
            }
        }

        // Setup EventChannel for real-time incoming SMS
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                SmsReceiver.smsListener = { sender, body, timestamp ->
                    runOnUiThread {
                        val data = mapOf(
                            "sender" to sender,
                            "body" to body,
                            "timestamp" to timestamp
                        )
                        eventSink?.success(data)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                SmsReceiver.smsListener = null
            }
        })

        // Setup MethodChannel for Notification Listener
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
                    val isGranted = enabledListeners.contains(packageName)
                    result.success(isGranted)
                }
                "requestNotificationPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                "getBufferedNotifications" -> {
                    val buffered = ExpenseNotificationListener.getAndClearBufferedNotifications(this)
                    result.success(buffered)
                }
                else -> result.notImplemented()
            }
        }

        // Setup EventChannel for real-time incoming push notifications
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                notifEventSink = events
                ExpenseNotificationListener.notificationListener = { pkg, title, text, timestamp ->
                    runOnUiThread {
                        val data = mapOf(
                            "packageName" to pkg,
                            "title" to title,
                            "text" to text,
                            "timestamp" to timestamp
                        )
                        notifEventSink?.success(data)
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                notifEventSink = null
                ExpenseNotificationListener.notificationListener = null
            }
        })
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionResultCallback?.success(allGranted)
            permissionResultCallback = null
        }
    }

    private fun readInboxMessages(limit: Int): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        try {
            val readGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
            if (!readGranted) return messages

            val cursor = contentResolver.query(
                Uri.parse("content://sms/inbox"),
                arrayOf("_id", "address", "body", "date"),
                null,
                null,
                "date DESC LIMIT $limit"
            )

            cursor?.use {
                val idCol = it.getColumnIndexOrThrow("_id")
                val addressCol = it.getColumnIndexOrThrow("address")
                val bodyCol = it.getColumnIndexOrThrow("body")
                val dateCol = it.getColumnIndexOrThrow("date")

                while (it.moveToNext()) {
                    val id = it.getString(idCol) ?: ""
                    val address = it.getString(addressCol) ?: ""
                    val body = it.getString(bodyCol) ?: ""
                    val date = it.getLong(dateCol)

                    messages.add(
                        mapOf(
                            "id" to id,
                            "sender" to address,
                            "body" to body,
                            "timestamp" to date
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return messages
    }
}
