package com.example.smart_expense

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmartExpense_SmsRecv"
        var smsListener: ((sender: String, body: String, timestamp: Long) -> Unit)? = null
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

                smsListener?.invoke(sender, fullBody, timestamp)
            } catch (e: Exception) {
                Log.e(TAG, "Error processing incoming SMS", e)
            }
        }
    }
}
