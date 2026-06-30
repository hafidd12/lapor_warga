import 'package:flutter/material.dart';

import 'custom_image_impl_stub.dart'
    if (dart.library.io) 'custom_image_impl_io.dart'
    if (dart.library.html) 'custom_image_impl_web.dart';

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
    return buildCustomImage(
      path: path,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
    );
  }
}

class CustomImageProvider {
  static ImageProvider get(String? path) {
    return buildCustomImageProvider(path);
  }
}
