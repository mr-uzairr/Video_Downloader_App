import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:video_downloader_app/controllers/download_controller.dart';

class VideoDownloaderApp extends StatelessWidget {
  const VideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const DownloaderHomePage(),
    );
  }
}

class DownloaderHomePage extends StatefulWidget {
  const DownloaderHomePage({super.key});

  @override
  State<DownloaderHomePage> createState() => _DownloaderHomePageState();
}

class _DownloaderHomePageState extends State<DownloaderHomePage> with WidgetsBindingObserver {
  late final DownloadController c;
  final TextEditingController urlController = TextEditingController();
  final RxString selectedQuality = 'best'.obs;

  final List<Map<String, String>> qualities = [
    {'value': 'best', 'label': 'Best Quality'},
    {'value': 'bestvideo+bestaudio', 'label': 'Best Video + Audio'},
    {'value': 'bestvideo[height<=720]+bestaudio', 'label': '720p'},
    {'value': 'bestvideo[height<=480]+bestaudio', 'label': '480p'},
    {'value': 'bestvideo[height<=360]+bestaudio', 'label': '360p'},
    {'value': 'worst', 'label': 'Lowest Quality'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c = Get.put(DownloadController());
    Get.log('DownloaderHomePage initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Get.log('DownloaderHomePage didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant DownloaderHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    Get.log('DownloaderHomePage didUpdateWidget');
  }

  @override
  void deactivate() {
    Get.log('DownloaderHomePage deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    urlController.dispose();
    try {
      c.onClose();
    } catch (_) {}
    Get.log('DownloaderHomePage dispose');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Get.log('AppLifecycleState changed: $state');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (c.videoController != null && c.videoController!.value.isPlaying) {
        c.videoController!.pause();
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildUrlCard(),
                const SizedBox(height: 16),
        Obx(() => c.hasPreview.value ? _buildVideoPreview() : const SizedBox()),
                const SizedBox(height: 24),
                _buildQualityCard(),
                const SizedBox(height: 32),
                _buildDownloadButton(),
                Obx(() => c.isDownloading.value
                    ? Column(
                        children: [
                          const SizedBox(height: 32),
                          _buildProgressCard(),
                        ],
                      )
                    : const SizedBox()),
                const SizedBox(height: 40),
                _buildSupportedPlatforms(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.purple.shade400,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.download_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Video Downloader',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Download videos from social media platforms',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUrlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, color: Colors.blue.shade400, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Video URL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'Paste video link here...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.video_library_rounded, color: Colors.grey[600]),
              ),
              onChanged: (val) {
                // update controller url and clear any previous preview when user edits the URL
                c.url.value = val;
                c.clearPreview();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.high_quality_rounded, color: Colors.purple.shade400, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Video Quality',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: qualities.map((quality) {
                return Obx(() {
                  final isSelected = selectedQuality.value == quality['value'];
                  return InkWell(
                    onTap: () => selectedQuality.value = quality['value']!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade400 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade400 : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        quality['label']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Obx(() => Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
            ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade400.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: c.isDownloading.value
                  ? null
                  : () => c.downloadVideo(inUrl: urlController.text.trim(), format: selectedQuality.value),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: c.isDownloading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Download Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ));
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Obx(() => Text(
                      c.downloadProgress.value == null
                          ? '...'
                          : '${(c.downloadProgress.value! * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue.shade400),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: c.downloadProgress.value,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                  ),
                )),
            const SizedBox(height: 12),
            Obx(() => Text(c.statusMessage.value, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedPlatforms() {
    final platforms = [
      {'icon': '📺', 'name': 'YouTube'},
      {'icon': '📸', 'name': 'Instagram'},
      {'icon': '🎵', 'name': 'TikTok'},
      {'icon': '🐦', 'name': 'Twitter'},
      {'icon': '📘', 'name': 'Facebook'},
      {'icon': '🔴', 'name': 'Reddit'},
    ];

    return Column(
      children: [
        const Text('Supported Platforms', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: platforms.map((platform) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(platform['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(platform['name']!, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    final vc = c.videoController!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: vc.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(vc),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(vc.value.isPlaying ? Icons.pause : Icons.play_arrow),
                          color: Colors.white,
                          onPressed: () => vc.value.isPlaying ? vc.pause() : vc.play(),
                        ),
                        const SizedBox(width: 8),
                        Obx(() => ElevatedButton.icon(
                              onPressed: (!c.hasPreview.value || c.downloadedFilePath.value == null) ? null : c.saveToGallery,
                              icon: const Icon(Icons.save_alt),
                              label: const Text('Save to Gallery'),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}

