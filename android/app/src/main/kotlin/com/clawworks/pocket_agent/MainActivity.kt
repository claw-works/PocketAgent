package com.clawworks.pocket_agent

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TERMUX_CHANNEL = "com.clawworks.pocket_agent/termux"
    private val INTENT_CHANNEL = "com.clawworks.pocket_agent/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupTermuxChannel(flutterEngine)
        setupIntentChannel(flutterEngine)
    }

    // ── Termux Channel ──────────────────────────────────────────

    private fun setupTermuxChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, TERMUX_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "runCommand" -> {
                        val command = call.argument<String>("command") ?: ""
                        val background = call.argument<Boolean>("background") ?: true
                        runTermuxCommand(command, background, result)
                    }
                    "isTermuxInstalled" -> result.success(isTermuxInstalled())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isTermuxInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo("com.termux", 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun runTermuxCommand(command: String, background: Boolean, result: MethodChannel.Result) {
        if (!isTermuxInstalled()) {
            result.error("TERMUX_NOT_FOUND", "Termux is not installed", null)
            return
        }

        val intent = Intent().apply {
            component = ComponentName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", command))
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", background)
            putExtra("com.termux.RUN_COMMAND_RESULT_SINGLE_LINE", false)
            putExtra("com.termux.RUN_COMMAND_RESULT_RECEIVER",
                object : ResultReceiver(Handler(Looper.getMainLooper())) {
                    override fun onReceiveResult(resultCode: Int, data: Bundle?) {
                        result.success(mapOf(
                            "stdout" to (data?.getString("stdout", "") ?: ""),
                            "stderr" to (data?.getString("stderr", "") ?: ""),
                            "exit_code" to (data?.getInt("exitCode", -1) ?: -1)
                        ))
                    }
                }
            )
        }

        try {
            startService(intent)
        } catch (e: Exception) {
            result.error("TERMUX_ERROR", e.message, null)
        }
    }

    // ── General Intent Channel ──────────────────────────────────

    private fun setupIntentChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchIntent" -> {
                        val action = call.argument<String>("action") ?: Intent.ACTION_VIEW
                        val uri = call.argument<String>("uri")
                        val pkg = call.argument<String>("package")
                        val extras = call.argument<Map<String, String>>("extras")
                        launchIntent(action, uri, pkg, extras, result)
                    }
                    "shareText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val title = call.argument<String>("title")
                        shareText(text, title, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchIntent(
        action: String, uri: String?, pkg: String?,
        extras: Map<String, String>?, result: MethodChannel.Result
    ) {
        try {
            val intent = Intent(action).apply {
                if (uri != null) data = Uri.parse(uri)
                if (pkg != null) setPackage(pkg)
                extras?.forEach { (k, v) -> putExtra(k, v) }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(mapOf("status" to "launched"))
        } catch (e: Exception) {
            result.error("INTENT_ERROR", e.message, null)
        }
    }

    private fun shareText(text: String, title: String?, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
            }
            startActivity(Intent.createChooser(intent, title ?: "分享").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
            result.success(mapOf("status" to "shared"))
        } catch (e: Exception) {
            result.error("SHARE_ERROR", e.message, null)
        }
    }
}
