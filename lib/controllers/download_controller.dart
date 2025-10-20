import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadController extends GetxController {
  final backendUrl = 'https://video-downloader-backend-2-hh82.onrender.com';

  var url = ''.obs;
  var isDownloading = false.obs;
  RxnDouble downloadProgress = RxnDouble();
  var statusMessage = ''.obs;
  var downloadedFilePath = RxnString();
  VideoPlayerController? videoController;
  /// true when a preview is available (controller initialized)
  var hasPreview = false.obs;

  final MethodChannel _channel = const MethodChannel('video_downloader/saveToGallery');


  @override
  void onClose() {
    videoController?.dispose();
    super.onClose();
  }

  Future<void> downloadVideo({String? inUrl, String? format}) async {
    final v = inUrl ?? url.value;
    if (v.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a video URL');
      return;
    }

    isDownloading.value = true;
    downloadProgress.value = 0.0;
    statusMessage.value = 'Starting download...';

    try {
  final qp = <String, String>{'url': v};
  if (format != null && format.isNotEmpty) qp['format'] = format;
  final uri = Uri.parse('$backendUrl/download').replace(queryParameters: qp);
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/octet-stream, application/json;q=0.9, */*;q=0.8';
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        if (contentLength == 0) {
          downloadProgress.value = null;
        } else {
          downloadProgress.value = 0.0;
        }

        final dir = await getApplicationDocumentsDirectory();
        final filename = _extractFilename(response.headers) ?? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final file = File('${dir.path}/$filename');

        int downloaded = 0;
        final sink = file.openWrite();

        await for (var chunk in response.stream) {
          sink.add(chunk);
          downloaded += chunk.length;

          if (contentLength > 0) {
            downloadProgress.value = downloaded / contentLength;
            statusMessage.value = 'Downloading: ${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB';
          } else {
            statusMessage.value = 'Downloading: ${(downloaded / 1024 / 1024).toStringAsFixed(2)} MB';
          }
        }

        await sink.close();

        downloadedFilePath.value = file.path;

        try {
          await videoController?.dispose();
        } catch (_) {}


  videoController = VideoPlayerController.file(file);
  await videoController!.initialize();
  videoController!.setLooping(false);
  // mark preview available for UI to reactively show
  hasPreview.value = true;

  isDownloading.value = false;
  downloadProgress.value = 1.0;
  statusMessage.value = 'Download completed!';

        Get.snackbar('Success', 'Video downloaded successfully');
      } else {
        isDownloading.value = false;
        statusMessage.value = 'Download failed';
        Get.snackbar('Error', 'Video download failed');
      }
    } catch (e) {
      isDownloading.value = false;
      statusMessage.value = 'Download failed';
      Get.snackbar('Error', 'Video download failed');
    }
  }

  String? _extractFilename(Map<String, String> headers) {
    final disposition = headers['content-disposition'];
    if (disposition != null) {
      final regex = RegExp(r'filename="?([^"]+)"?');
      final match = regex.firstMatch(disposition);
      return match?.group(1);
    }
    return null;
  }

  Future<void> saveToGallery() async {
    if (downloadedFilePath.value == null) return;
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Get.snackbar('Error', 'Storage permission denied');
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        if (!status.isGranted) {
          Get.snackbar('Error', 'Photo library permission denied');
          return;
        }
      }

      final res = await _channel.invokeMethod('saveToGallery', {'path': downloadedFilePath.value});
      if (res != null) {
        Get.snackbar('Success', 'Video saved to gallery');
      } else {
        Get.snackbar('Error', 'Failed to save to gallery');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save to gallery');
    }
  }

  Future<void> clearPreview() async {
    downloadedFilePath.value = null;
    try {
      await videoController?.dispose();
    } catch (_) {}
    videoController = null;
    downloadProgress.value = null;
    statusMessage.value = '';
    hasPreview.value = false;
  }
}
