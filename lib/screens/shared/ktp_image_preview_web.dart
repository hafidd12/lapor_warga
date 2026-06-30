import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ktp_image_preview_base.dart';

class WebKtpImagePreview extends KtpImagePreview {
  WebKtpImagePreview({
    required this.bytesValue,
    required this.fileNameValue,
  });

  final Uint8List bytesValue;
  final String fileNameValue;

  @override
  Uint8List get bytes => bytesValue;

  @override
  String get fileName => fileNameValue;

  @override
  String? get localPath => null;

  @override
  Widget buildPreview({required BorderRadius borderRadius}) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox.expand(
          child: Image.memory(
            bytesValue,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            cacheWidth: 1400,
          ),
        ),
      ),
    );
  }
}

Future<KtpImagePreview> createKtpImagePreviewFromXFile(XFile file) async {
  final bytes = await file.readAsBytes();
  final fileName = file.name.trim().isNotEmpty ? file.name : 'ktp-image';

  return WebKtpImagePreview(bytesValue: bytes, fileNameValue: fileName);
}
