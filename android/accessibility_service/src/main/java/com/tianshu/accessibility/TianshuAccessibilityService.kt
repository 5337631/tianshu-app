package com.tianshu.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.io.StringWriter

class TianshuAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "TianshuA11y"
        var instance: TianshuAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        Log.d(TAG, "无障碍服务已连接")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {
        Log.d(TAG, "无障碍服务被中断")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "无障碍服务已销毁")
    }

    fun getUiHierarchy(): String {
        val rootNode = rootInActiveWindow ?: return ""
        val writer = StringWriter()
        serializeNode(rootNode, writer, 0)
        return writer.toString()
    }

    private fun serializeNode(node: AccessibilityNodeInfo, writer: StringWriter, depth: Int) {
        val indent = "  ".repeat(depth)
        val bounds = android.graphics.Rect()
        node.getBoundsInScreen(bounds)

        writer.append("$indent<node")
        writer.append(" ref=\"${node.hashCode()}\"")
        writer.append(" class=\"${node.className}\"")
        writer.append(" package=\"${node.packageName}\"")
        writer.append(" text=\"${escapeXml(node.text?.toString() ?: "")}\"")
        writer.append(" content-desc=\"${escapeXml(node.contentDescription?.toString() ?: "")}\"")
        writer.append(" bounds=\"[${bounds.left},${bounds.top}][${bounds.right},${bounds.bottom}]\"")
        writer.append(" clickable=\"${node.isClickable}\"")
        writer.append(" focusable=\"${node.isFocusable}\"")
        writer.append(" enabled=\"${node.isEnabled}\"")
        writer.append(" focused=\"${node.isFocused}\"")
        writer.append(" selected=\"${node.isSelected}\"")
        writer.append(" checkable=\"${node.isCheckable}\"")
        writer.append(" checked=\"${node.isChecked}\"")

        if (node.childCount == 0) {
            writer.append(" />\n")
        } else {
            writer.append(">\n")
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                serializeNode(child, writer, depth + 1)
                child.recycle()
            }
            writer.append("$indent</node>\n")
        }
    }

    private fun escapeXml(text: String): String {
        return text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }

    fun performClick(x: Int, y: Int): Boolean {
        val path = android.graphics.Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val stroke = android.accessibilityservice.GestureDescription.StrokeDescription(path, 0, 50)
        val gesture = android.accessibilityservice.GestureDescription.Builder().addStroke(stroke).build()
        return dispatchGesture(gesture, null, null)
    }

    fun performLongPress(x: Int, y: Int): Boolean {
        val path = android.graphics.Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val stroke = android.accessibilityservice.GestureDescription.StrokeDescription(path, 0, 1000)
        val gesture = android.accessibilityservice.GestureDescription.Builder().addStroke(stroke).build()
        return dispatchGesture(gesture, null, null)
    }

    fun performSwipe(startX: Int, startY: Int, endX: Int, endY: Int, duration: Long): Boolean {
        val path = android.graphics.Path().apply {
            moveTo(startX.toFloat(), startY.toFloat())
            lineTo(endX.toFloat(), endY.toFloat())
        }
        val stroke = android.accessibilityservice.GestureDescription.StrokeDescription(path, 0, duration)
        val gesture = android.accessibilityservice.GestureDescription.Builder().addStroke(stroke).build()
        return dispatchGesture(gesture, null, null)
    }

    fun performGlobal(actionId: Int): Boolean {
        return performGlobalAction(actionId)
    }

    fun findFocusedNodeId(): String? {
        val focused = findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY)
        return focused?.hashCode().toString()
    }

    fun setTextOnNode(nodeId: String, text: String): Boolean {
        val node = findNodeById(nodeId) ?: return false
        val arguments = android.os.Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    fun takeScreenshot(path: String, format: String): Boolean {
        return false
    }

    fun isAccessibilityServiceEnabled(): Boolean {
        return serviceInfo != null
    }

    fun getCurrentActivityName(): String? {
        val rootNode = rootInActiveWindow ?: return null
        return rootNode.className?.toString()
    }

    private fun findNodeById(nodeId: String): AccessibilityNodeInfo? {
        val rootNode = rootInActiveWindow ?: return null
        return findNodeRecursive(rootNode, nodeId)
    }

    private fun findNodeRecursive(node: AccessibilityNodeInfo, targetId: String): AccessibilityNodeInfo? {
        if (node.hashCode().toString() == targetId) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findNodeRecursive(child, targetId)
            if (found != null) return found
            child.recycle()
        }
        return null
    }
}
