package com.example.video_downloader_app

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {
	private val CHANNEL = "video_downloader/saveToGallery"

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "saveToGallery") {
				val path = call.argument<String>("path")
				if (path == null) {
					result.error("invalid_args", "Missing path", null)
					return@setMethodCallHandler
				}

				try {
					val savedUri = saveVideoToGallery(this, path)
					if (savedUri != null) {
						result.success(savedUri.toString())
					} else {
						result.error("save_failed", "Failed to save video", null)
					}
				} catch (e: Exception) {
					Log.e("MainActivity", "saveToGallery error", e)
					result.error("exception", e.localizedMessage, null)
				}
			} else {
				result.notImplemented()
			}
		}
	}

	private fun saveVideoToGallery(context: Context, srcPath: String): android.net.Uri? {
		val srcFile = File(srcPath)
		if (!srcFile.exists()) return null

		val displayName = srcFile.name
		val mimeType = "video/mp4"

		val resolver = context.contentResolver

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val contentValues = ContentValues().apply {
				put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
				put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
				put(MediaStore.MediaColumns.RELATIVE_PATH, "Movies/VideoDownloader")
			}

			val uri = resolver.insert(MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY), contentValues)
			if (uri != null) {
				resolver.openOutputStream(uri).use { out: OutputStream? ->
					FileInputStream(srcFile).use { input ->
						input.copyTo(out!!)
					}
				}
				return uri
			}
		} else {
			// Legacy path
			val values = ContentValues().apply {
				put(MediaStore.MediaColumns.DATA, srcFile.absolutePath)
				put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
				put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
			}
			return resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
		}

		return null
	}
}
