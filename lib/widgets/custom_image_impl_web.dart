import 'package:flutter/material.dart';

Widget buildCustomImage({
  required String? path,
  required BoxFit fit,
  required double? width,
  required double? height,
  required Widget? placeholder,
}) {
  if (path == null || path.trim().isEmpty) {
    return buildCustomImagePlaceholder(
      width: width,
      height: height,
      placeholder: placeholder,
    );
  }

  final String imagePath = path.trim();

  if (imagePath.startsWith('http://') ||
      imagePath.startsWith('https://') ||
      imagePath.startsWith('blob:')) {
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          buildCustomImagePlaceholder(
            width: width,
            height: height,
            placeholder: placeholder,
          ),
    );
  }

  if (imagePath.startsWith('mock://')) {
    return Image.network(
      'https://picsum.photos/seed/${imagePath.hashCode}/600/400',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          buildCustomImagePlaceholder(
            width: width,
            height: height,
            placeholder: placeholder,
          ),
    );
  }

  return buildCustomImagePlaceholder(
    width: width,
    height: height,
    placeholder: placeholder,
  );
}

ImageProvider buildCustomImageProvider(String? path) {
  if (path == null || path.trim().isEmpty) {
    return const AssetImage('assets/images/placeholder.png');
  }

  final String imagePath = path.trim();
  if (imagePath.startsWith('http://') ||
      imagePath.startsWith('https://') ||
      imagePath.startsWith('blob:')) {
    return NetworkImage(imagePath);
  }

  if (imagePath.startsWith('mock://')) {
    return NetworkImage(
      'https://picsum.photos/seed/${imagePath.hashCode}/150/150',
    );
  }

  return const NetworkImage('https://via.placeholder.com/150');
}

Widget buildCustomImagePlaceholder({
  required double? width,
  required double? height,
  required Widget? placeholder,
}) {
  if (placeholder != null) return placeholder;

  return Container(
    width: width,
    height: height,
    color: Colors.black12,
    child: const Center(child: Icon(Icons.photo_outlined)),
  );
}
