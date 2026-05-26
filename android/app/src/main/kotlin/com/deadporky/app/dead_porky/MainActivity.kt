package com.deadporky.app.dead_porky

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
	private var huaweiHealthKitBridge: HuaweiHealthKitBridge? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		huaweiHealthKitBridge = HuaweiHealthKitBridge(
			activity = this,
			messenger = flutterEngine.dartExecutor.binaryMessenger,
		)
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		if (huaweiHealthKitBridge?.onActivityResult(requestCode, resultCode, data) == true) {
			return
		}
		super.onActivityResult(requestCode, resultCode, data)
	}
}
