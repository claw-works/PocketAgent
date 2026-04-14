package com.clawworks.pocket_agent

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * PocketAgent Accessibility Service.
 *
 * Provides screen reading and UI automation capabilities:
 * - Read UI tree (all visible elements)
 * - Click elements by text/id/index
 * - Input text into focused fields
 * - Scroll, swipe, tap by coordinates
 * - Global actions (back, home, recents, notifications)
 */
class PocketAgentAccessibilityService : AccessibilityService() {

    companion object {
        var instance: PocketAgentAccessibilityService? = null
            private set

        fun isRunning(): Boolean = instance != null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    // ── Read Screen ─────────────────────────────────────────────

    /** Flatten the UI tree into a list of element maps. */
    fun readScreen(): List<Map<String, Any?>> {
        val root = rootInActiveWindow ?: return emptyList()
        val elements = mutableListOf<Map<String, Any?>>()
        traverseNode(root, elements, 0)
        root.recycle()
        return elements
    }

    private fun traverseNode(
        node: AccessibilityNodeInfo,
        out: MutableList<Map<String, Any?>>,
        index: Int
    ) {
        val rect = Rect()
        node.getBoundsInScreen(rect)

        // Only include visible, meaningful nodes
        if (rect.width() > 0 && rect.height() > 0) {
            out.add(mapOf(
                "index" to index,
                "class" to node.className?.toString(),
                "text" to node.text?.toString(),
                "description" to node.contentDescription?.toString(),
                "id" to node.viewIdResourceName,
                "clickable" to node.isClickable,
                "editable" to node.isEditable,
                "scrollable" to node.isScrollable,
                "checked" to node.isChecked,
                "focused" to node.isFocused,
                "bounds" to mapOf(
                    "left" to rect.left, "top" to rect.top,
                    "right" to rect.right, "bottom" to rect.bottom
                )
            ))
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            traverseNode(child, out, out.size)
            child.recycle()
        }
    }

    // ── Click ───────────────────────────────────────────────────

    /** Find a node matching criteria and click it. */
    fun clickByText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val nodes = root.findAccessibilityNodeInfosByText(text)
        val target = nodes.firstOrNull { it.isClickable }
            ?: nodes.firstOrNull()?.findClickableParent()
        val result = target?.performAction(AccessibilityNodeInfo.ACTION_CLICK) ?: false
        root.recycle()
        return result
    }

    fun clickByIndex(index: Int): Boolean {
        val elements = readScreen()
        if (index < 0 || index >= elements.size) return false
        val bounds = elements[index]["bounds"] as? Map<*, *> ?: return false
        val cx = ((bounds["left"] as Int) + (bounds["right"] as Int)) / 2f
        val cy = ((bounds["top"] as Int) + (bounds["bottom"] as Int)) / 2f
        return tapAt(cx, cy)
    }

    fun tapAt(x: Float, y: Float): Boolean {
        val path = Path().apply { moveTo(x, y) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 100))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    // ── Text Input ──────────────────────────────────────────────

    /** Set text on the currently focused editable field. */
    fun inputText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val focused = findFocusedEditable(root)
        if (focused != null) {
            val args = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            val result = focused.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
            root.recycle()
            return result
        }
        root.recycle()
        return false
    }

    private fun findFocusedEditable(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused && node.isEditable) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findFocusedEditable(child)
            if (found != null) return found
            child.recycle()
        }
        return null
    }

    // ── Scroll / Swipe ──────────────────────────────────────────

    fun swipe(x1: Float, y1: Float, x2: Float, y2: Float, durationMs: Long = 300): Boolean {
        val path = Path().apply {
            moveTo(x1, y1)
            lineTo(x2, y2)
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, durationMs))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    // ── Global Actions ──────────────────────────────────────────

    fun pressBack(): Boolean = performGlobalAction(GLOBAL_ACTION_BACK)
    fun pressHome(): Boolean = performGlobalAction(GLOBAL_ACTION_HOME)
    fun pressRecents(): Boolean = performGlobalAction(GLOBAL_ACTION_RECENTS)
    fun openNotifications(): Boolean = performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)

    // ── Helpers ─────────────────────────────────────────────────

    private fun AccessibilityNodeInfo.findClickableParent(): AccessibilityNodeInfo? {
        var current = this.parent
        while (current != null) {
            if (current.isClickable) return current
            current = current.parent
        }
        return null
    }
}
