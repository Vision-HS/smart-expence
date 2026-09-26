package com.visionhs.smartexpense

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmartExpense_SmsRecv"
        const val PREFS_NAME = "smart_expense_sms_buffer"
        const val KEY_BUFFER = "buffered_sms_list"

        var smsListener: ((sender: String, body: String, timestamp: Long) -> Unit)? = null

        fun getAndClearBufferedMessages(context: Context): List<Map<String, Any>> {
            val list = mutableListOf<Map<String, Any>>()
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(KEY_BUFFER, null) ?: return list

            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    list.add(
                        mapOf(
                            "sender" to obj.optString("sender", ""),
                            "body" to obj.optString("body", ""),
                            "timestamp" to obj.optLong("timestamp", System.currentTimeMillis())
                        )
                    )
                }
                prefs.edit().remove(KEY_BUFFER).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing buffered SMS", e)
            }
            return list
        }

        fun saveMessageToBuffer(context: Context, sender: String, body: String, timestamp: Long) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingStr = prefs.getString(KEY_BUFFER, "[]") ?: "[]"
                val array = JSONArray(existingStr)

                val newObj = JSONObject().apply {
                    put("sender", sender)
                    put("body", body)
                    put("timestamp", timestamp)
                }
                array.put(newObj)
                prefs.edit().putString(KEY_BUFFER, array.toString()).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error saving SMS to buffer", e)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            try {
                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                if (messages.isNullOrEmpty()) return

                val sender = messages[0].displayOriginatingAddress ?: ""
                val timestamp = messages[0].timestampMillis
                val bodyBuilder = StringBuilder()

                for (msg in messages) {
                    msg.displayMessageBody?.let {
                        bodyBuilder.append(it)
                    }
                }

                val fullBody = bodyBuilder.toString()
                Log.d(TAG, "SMS Received from $sender: $fullBody")

                if (smsListener != null) {
                    smsListener?.invoke(sender, fullBody, timestamp)
                } else {
                    // App is closed or backgrounded: save to buffer so Flutter reads it on resume/launch
                    saveMessageToBuffer(context, sender, fullBody, timestamp)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing incoming SMS", e)
            }
        }
    }
}
