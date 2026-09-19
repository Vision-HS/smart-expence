package com.example.smart_expense

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class ExpenseNotificationListener : NotificationListenerService() {
    companion object {
        private const val TAG = "SmartExpense_Notif"
        const val PREFS_NAME = "smart_expense_notif_buffer"
        const val KEY_BUFFER = "buffered_notif_list"

        var notificationListener: ((packageName: String, title: String, text: String, timestamp: Long) -> Unit)? = null

        fun getAndClearBufferedNotifications(context: Context): List<Map<String, Any>> {
            val list = mutableListOf<Map<String, Any>>()
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(KEY_BUFFER, null) ?: return list

            try {
                val array = JSONArray(jsonStr)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    list.add(
                        mapOf(
                            "packageName" to obj.optString("packageName", ""),
                            "title" to obj.optString("title", ""),
                            "text" to obj.optString("text", ""),
                            "timestamp" to obj.optLong("timestamp", System.currentTimeMillis())
                        )
                    )
                }
                prefs.edit().remove(KEY_BUFFER).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing buffered notifications", e)
            }
            return list
        }

        fun saveNotificationToBuffer(context: Context, packageName: String, title: String, text: String, timestamp: Long) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingStr = prefs.getString(KEY_BUFFER, "[]") ?: "[]"
                val array = JSONArray(existingStr)

                val newObj = JSONObject().apply {
                    put("packageName", packageName)
                    put("title", title)
                    put("text", text)
                    put("timestamp", timestamp)
                }
                array.put(newObj)
                prefs.edit().putString(KEY_BUFFER, array.toString()).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error saving notification to buffer", e)
            }
        }

        private val KNOWN_FINANCIAL_PACKAGES = setOf(
            "com.google.android.apps.nbu.paisa.user", // Google Pay
            "com.phonepe.app",                       // PhonePe
            "net.one97.paytm",                       // Paytm
            "in.org.npci.upiapp",                    // BHIM
            "com.dreamplug.androidapp",               // CRED
            "in.amazon.mShop.android.shopping",      // Amazon Pay
            "com.sbi.lotusintouch",                  // YONO SBI
            "com.sbi.SBIFreedomPlus",                // SBI YONO Lite
            "com.snapwork.hdfc",                     // HDFC MobileBanking
            "com.csam.icici.bank.imobile",           // ICICI iMobile Pay
            "com.axis.mobile",                       // Axis Mobile
            "com.msf.kbank.mobile",                  // Kotak Mobile Banking
            "com.bob.bobmobile",                     // Bank of Baroda bob World
            "com.pnb.one",                           // PNB ONE
            "com.canarabank.ai1"                     // Canara ai1
        )

        fun isPotentialFinancialNotification(packageName: String, title: String, text: String): Boolean {
            val lowerTitle = title.lowercase()
            val lowerText = text.lowercase()
            val fullContent = "$lowerTitle $lowerText"

            val isKnownPackage = KNOWN_FINANCIAL_PACKAGES.contains(packageName)

            val hasMoney = fullContent.contains("₹") || 
                           fullContent.contains("rs.") || 
                           fullContent.contains("rs ") || 
                           fullContent.contains("inr")

            val hasTxAction = fullContent.contains("paid") ||
                              fullContent.contains("sent") ||
                              fullContent.contains("debited") ||
                              fullContent.contains("credited") ||
                              fullContent.contains("received") ||
                              fullContent.contains("transferred") ||
                              fullContent.contains("spent") ||
                              fullContent.contains("payment")

            // Filter out marketing & loan promos
            if (fullContent.contains("cashback up to") || 
                fullContent.contains("pre-approved") ||
                fullContent.contains("apply now") ||
                fullContent.contains("instant loan") ||
                fullContent.contains("voucher worth") ||
                fullContent.contains("flat discount") ||
                fullContent.contains("use code")) {
                return false
            }

            if (isKnownPackage) {
                return (hasMoney && hasTxAction) || (hasMoney && (lowerTitle.contains("paid") || lowerTitle.contains("received") || lowerTitle.contains("payment")))
            }

            return hasMoney && hasTxAction
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return

        // Ignore notifications posted by our own app
        if (packageName == applicationContext.packageName) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getString(Notification.EXTRA_TITLE)
            ?: extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
            ?: ""

        var text = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        if (text.isNullOrEmpty()) {
            text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        }

        if (text.isBlank() && title.isBlank()) return

        val timestamp = sbn.postTime

        if (isPotentialFinancialNotification(packageName, title, text)) {
            Log.d(TAG, "Financial notification captured from $packageName: [$title] $text")
            val listener = notificationListener
            if (listener != null) {
                listener.invoke(packageName, title, text, timestamp)
            } else {
                saveNotificationToBuffer(applicationContext, packageName, title, text, timestamp)
            }
        }
    }
}
