package com.tianshu.tianshu

import android.app.Notification
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * 通知监听服务 — 读取通知栏消息
 * Flutter 侧通过 MethodChannel("com.tianshu.accessibility") 调用 getNotifications
 */
class TianshuNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "TianshuNotifListener"
        var instance: TianshuNotificationListener? = null
            private set
    }

    private val _notifications = mutableListOf<Map<String, Any>>()

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        Log.d(TAG, "通知监听服务已连接")
        // 加载当前通知
        refreshNotifications()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        instance = null
        Log.d(TAG, "通知监听服务已断开")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        try {
            val notification = sbn.notification ?: return
            val extras = notification.extras ?: return

            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: text
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
            val packageName = sbn.packageName
            val timestamp = sbn.postTime
            val isGroupSummary = (sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0

            // 从包名推断应用名
            val appName = getAppName(packageName)

            val notif = mapOf<String, Any>(
                "app" to appName,
                "title" to title,
                "body" to bigText.ifEmpty { text },
                "subText" to subText,
                "packageName" to packageName,
                "timestamp" to timestamp,
                "isGroupSummary" to isGroupSummary,
                "key" to sbn.key
            )

            // 去重（按 key）
            _notifications.removeAll { it["key"] == sbn.key }
            _notifications.add(0, notif)

            // 限制最多 50 条
            while (_notifications.size > 50) {
                _notifications.removeAt(_notifications.size - 1)
            }

            Log.d(TAG, "收到通知: [$appName] $title - $text")
        } catch (e: Exception) {
            Log.e(TAG, "处理通知失败", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        sbn ?: return
        try {
            _notifications.removeAll { it["key"] == sbn.key }
        } catch (e: Exception) {
            Log.e(TAG, "移除通知失败", e)
        }
    }

    /**
     * 获取当前所有通知
     * Flutter 侧调用：MethodChannel("com.tianshu.accessibility").invokeMethod("getNotifications")
     */
    fun getNotifications(): List<Map<String, Any>> {
        refreshNotifications()
        return _notifications.toList()
    }

    private fun refreshNotifications() {
        try {
            val activeNotifications = activeNotifications
            if (activeNotifications != null) {
                _notifications.clear()
                for (sbn in activeNotifications) {
                    val notification = sbn.notification ?: continue
                    val extras = notification.extras ?: continue

                    val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
                    val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
                    val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: text
                    val isGroupSummary = (sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0

                    _notifications.add(mapOf<String, Any>(
                        "app" to getAppName(sbn.packageName),
                        "title" to title,
                        "body" to bigText.ifEmpty { text },
                        "subText" to (extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""),
                        "packageName" to sbn.packageName,
                        "timestamp" to sbn.postTime,
                        "isGroupSummary" to isGroupSummary,
                        "key" to sbn.key
                    ))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "刷新通知失败", e)
        }
    }

    private fun getAppName(packageName: String): String {
        return when {
            packageName.contains("com.tencent.mm") -> "微信"
            packageName.contains("com.tencent.mobileqq") -> "QQ"
            packageName.contains("com.eg.android.AlipayGphone") -> "支付宝"
            packageName.contains("com.ss.android.ugc.aweme") -> "抖音"
            packageName.contains("com.taobao.taobao") -> "淘宝"
            packageName.contains("com.autonavi.minimap") -> "高德地图"
            packageName.contains("com.google.android.gm") -> "Gmail"
            packageName.contains("com.microsoft.office.outlook") -> "Outlook"
            packageName.contains("org.telegram.messenger") -> "Telegram"
            packageName.contains("com.twitter.android") -> "X/Twitter"
            packageName.contains("com.alibaba.android.rimet") -> "钉钉"
            packageName.contains("com.ss.android.lark") -> "飞书"
            packageName.contains("com.discord") -> "Discord"
            packageName.contains("com.slack") -> "Slack"
            packageName.contains("com.android.mms") -> "短信"
            packageName.contains("com.android.dialer") -> "电话"
            packageName.contains("com.android.calendar") -> "日历"
            packageName.contains("com.android.email") -> "邮件"
            else -> packageName.substringAfterLast('.')
        }
    }
}
