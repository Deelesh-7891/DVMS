import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// Renders a small tappable thumbnail for a server-hosted photo (bill,
/// insurance doc, accident photo, etc.), given the root-relative path the
/// backend returns (e.g. "/uploads/xxxx.jpg"). Tapping it opens a zoomable
/// full-screen view. Returns an empty box when there's no photo, so callers
/// can drop this in unconditionally.
class PhotoThumbnail extends StatelessWidget {
  final String? photoPath;
  final double size;

  const PhotoThumbnail({
    super.key,
    required this.photoPath,
    this.size = 44,
  });

  String? get _url {
    if (photoPath == null || photoPath!.trim().isEmpty) return null;
    // Server returns PhotoPath as a root-relative path — baseUrl already
    // ends in "/api", so strip that to get the host the file actually
    // lives under.
    final host = AuthService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return "$host$photoPath";
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;

    if (url == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: Image.network(
              url,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey.shade100,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
