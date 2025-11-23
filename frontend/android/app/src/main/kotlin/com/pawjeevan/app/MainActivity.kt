package com.pawjeevan.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
	// Explicitly register plugins to ensure plugins are available on startup.
	// This can help avoid MissingPluginException in some build/runtime setups.
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		GeneratedPluginRegistrant.registerWith(flutterEngine)
	}
}
