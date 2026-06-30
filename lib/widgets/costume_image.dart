import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme.dart';

class CustomImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const CustomImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) {
      return _buildPlaceholder();
    }

    final String imagePath = path!.trim();

    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('blob:')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (imagePath.startsWith('mock://')) {
      // Handle mock data specifically
      return Image.network(
        'https://picsum.photos/seed/${imagePath.hashCode}/600/400',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      // Local file path
      if (kIsWeb) {
        // On web, if it's not a blob or http, it's invalid.
        return _buildPlaceholder();
      } else {
        return Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceContainerHigh,
      child: const Center(
        child: Icon(
          Icons.photo_outlined,
          color: AppTheme.outlineColor,
          size: 34,
        ),
      ),
    );
  }
}

class CustomImageProvider {
  static ImageProvider get(String? path) {
    if (path == null || path.trim().isEmpty) {
      return const AssetImage('assets/images/placeholder.png'); // fallback
    }

    final String imagePath = path.trim();
    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('blob:')) {
      return NetworkImage(imagePath);
    } else if (imagePath.startsWith('mock://')) {
      return NetworkImage(
        'https://picsum.photos/seed/${imagePath.hashCode}/150/150',
      );
    } else {
      if (kIsWeb) {
        return const NetworkImage(
          'https://via.placeholder.com/150',
        ); // Safe fallback for web
      } else {
        return FileImage(File(imagePath));
      }
    }
  }
}
