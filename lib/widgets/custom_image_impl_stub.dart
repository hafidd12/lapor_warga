import 'package:flutter/material.dart';

Widget buildCustomImage({
  required String? path,
  required BoxFit fit,
  required double? width,
  required double? height,
  required Widget? placeholder,
}) {
  return buildCustomImagePlaceholder(
    width: width,
    height: height,
    placeholder: placeholder,
  );
}

ImageProvider buildCustomImageProvider(String? path) {
  return const AssetImage('assets/images/placeholder.png');
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
