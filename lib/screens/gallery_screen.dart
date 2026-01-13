import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/auth_service.dart';

class GalleryScreen extends StatefulWidget {
  final String memberName;

  const GalleryScreen({super.key, required this.memberName});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _mediaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/gallery'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _mediaList = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load media');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('미디어 목록을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  Future<void> _uploadMedia(XFile file, String type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/gallery'),
      );

      request.fields['uploader_name'] = widget.memberName;
      request.fields['file_type'] = type;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: file.name,
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        _fetchMedia(); // Refresh list
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('업로드 성공!')));
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('사진 선택'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    _uploadMedia(image, 'IMAGE');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('동영상 선택'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? video = await _picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (video != null) {
                    _uploadMedia(video, 'VIDEO');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('갤러리'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final media = _mediaList[index];
                final isVideo = media['file_type'] == 'VIDEO';
                // Replace 'uploads/' with 'images/' for the URL
                final filePath = media['file_path'] as String;
                final urlPath = filePath.replaceFirst('uploads/', 'images/');
                final url = '${AuthService.baseUrl}/$urlPath';
                final mediaId = media['id'];

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaDetailScreen(
                          url: url,
                          isVideo: isVideo,
                          mediaId: mediaId,
                        ),
                      ),
                    );

                    if (result == true) {
                      _fetchMedia();
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: isVideo
                            ? '${AuthService.baseUrl}/${(media['thumbnail_path'] ?? filePath).replaceFirst('uploads/', 'images/')}'
                            : url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      if (isVideo)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPicker(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MediaDetailScreen extends StatefulWidget {
  final String url;
  final bool isVideo;
  final int mediaId;

  const MediaDetailScreen({
    super.key,
    required this.url,
    required this.isVideo,
    required this.mediaId,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
    );
    setState(() {});
  }

  Future<void> _deleteMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('${AuthService.baseUrl}/gallery/${widget.mediaId}'),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            Navigator.pop(context, true); // Return true to refresh list
          }
        } else {
          throw Exception('Failed to delete media');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteMedia),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: widget.isVideo
            ? _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const CircularProgressIndicator()
            : InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.url,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}
