import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/message.dart';
import '../../data/services/file_service.dart';
import '../../core/di/service_locator.dart';

/// Media viewer widget for images, videos, and audio files
class MediaViewer extends StatefulWidget {
  final MessageAttachment attachment;
  final String messageType;

  const MediaViewer({
    super.key,
    required this.attachment,
    required this.messageType,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final FileService _fileService = serviceLocator.get<FileService>();

  @override
  void initState() {
    super.initState();
    if (widget.messageType == 'video') {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() async {
    final videoUrl = _fileService.getStreamUrl(widget.attachment.filePath);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.attachment.filePath.split('/').last,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadFile(),
          ),
        ],
      ),
      body: Center(
        child: _buildMediaContent(),
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (widget.messageType) {
      case 'image':
        return _buildImageViewer();
      case 'video':
        return _buildVideoViewer();
      case 'audio':
        return _buildAudioPlayer();
      default:
        return _buildFileInfo();
    }
  }

  Widget _buildImageViewer() {
    final imageUrl = _fileService.getStreamUrl(widget.attachment.filePath);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'فشل في تحميل الصورة',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.replay, color: Colors.white, size: 32),
              onPressed: () {
                _videoController!.seekTo(Duration.zero);
                _videoController!.play();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        VideoProgressIndicator(
          _videoController!,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Colors.blue,
            bufferedColor: Colors.grey,
            backgroundColor: Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            widget.attachment.filePath.split('/').last,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatFileSize(widget.attachment.fileSize),
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement audio player
              _showNotImplementedSnackBar('مشغل الصوت');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('تشغيل'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getFileIcon(), size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            widget.attachment.filePath.split('/').last,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatFileSize(widget.attachment.fileSize),
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _downloadFile(),
            icon: const Icon(Icons.download),
            label: const Text('تحميل'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    final extension = widget.attachment.filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
  }

  void _downloadFile() {
    // TODO: Implement file download functionality
    _showNotImplementedSnackBar('تحميل الملف');
  }

  void _showNotImplementedSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature غير متوفر حالياً'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// Show media viewer dialog
void showMediaViewer(BuildContext context, MessageAttachment attachment, String messageType) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => MediaViewer(
        attachment: attachment,
        messageType: messageType,
      ),
    ),
  );
}
