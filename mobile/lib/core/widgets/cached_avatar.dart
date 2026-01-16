import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/custom_cache_manager.dart';

class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String fallbackText;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackText = '?',
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Text(
          fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            fontSize: radius * 0.6,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          cacheManager: CustomCacheManager.instance,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (radius * 2 * 2).toInt(), // 2x for retina
          memCacheHeight: (radius * 2 * 2).toInt(),
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Text(
            fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: radius * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
