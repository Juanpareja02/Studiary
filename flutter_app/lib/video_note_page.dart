import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoNotePage extends StatefulWidget {
  const VideoNotePage({super.key, required this.title, required this.url});
  final String title;
  final String url;
  @override
  State<VideoNotePage> createState() => _VideoNotePageState();
}

class _VideoNotePageState extends State<VideoNotePage>
    with WidgetsBindingObserver {
  late final controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'No se pudo reproducir. Comprueba la conexión y el formato del vídeo.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) controller.pause();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: error != null
              ? Text(error!, textAlign: TextAlign.center)
              : !controller.value.isInitialized
              ? const CircularProgressIndicator()
              : ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AspectRatio(
                          aspectRatio: value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                      ),
                      if (value.hasError)
                        const Text(
                          'Se interrumpió la reproducción. Vuelve a abrir el vídeo.',
                        ),
                      VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Retroceder 10 segundos',
                            onPressed: () => controller.seekTo(
                              Duration(
                                milliseconds:
                                    (value.position.inMilliseconds - 10000)
                                        .clamp(
                                          0,
                                          value.duration.inMilliseconds,
                                        ),
                              ),
                            ),
                            icon: const Icon(Icons.replay_10),
                          ),
                          IconButton.filled(
                            tooltip: value.isPlaying ? 'Pausar' : 'Reproducir',
                            onPressed: () async {
                              if (value.position >= value.duration) {
                                await controller.seekTo(Duration.zero);
                              }
                              value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            },
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                          PopupMenuButton<double>(
                            tooltip: 'Velocidad',
                            initialValue: value.playbackSpeed,
                            onSelected: controller.setPlaybackSpeed,
                            itemBuilder: (_) => [0.75, 1.0, 1.25, 1.5, 2.0]
                                .map(
                                  (speed) => PopupMenuItem(
                                    value: speed,
                                    child: Text('${speed}x'),
                                  ),
                                )
                                .toList(),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('${value.playbackSpeed}x'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}
