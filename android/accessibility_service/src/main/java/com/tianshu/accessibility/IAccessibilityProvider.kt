package com.tianshu.accessibility

interface IAccessibilityProvider {
    fun getUiHierarchy(): String
    fun performClick(x: Int, y: Int): Boolean
    fun performLongPress(x: Int, y: Int): Boolean
    fun performGlobalAction(actionId: Int): Boolean
    fun performSwipe(startX: Int, startY: Int, endX: Int, endY: Int, duration: Long): Boolean
    fun findFocusedNodeId(): String?
    fun setTextOnNode(nodeId: String, text: String): Boolean
    fun takeScreenshot(path: String, format: String): Boolean
    fun isAccessibilityServiceEnabled(): Boolean
    fun getCurrentActivityName(): String?
}
