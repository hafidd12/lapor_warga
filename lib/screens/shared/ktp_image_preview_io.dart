import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ktp_image_preview_base.dart';

class IoKtpImagePreview extends KtpImagePreview {
  IoKtpImagePreview({
    required this.file,
    required this.bytesValue,
    required this.fileNameValue,
  });

  final File file;
  final Uint8List bytesValue;
  final String fileNameValue;

  @override
  Uint8List get bytes => bytesValue;

  @override
  String get fileName => fileNameValue;

  @override
  String? get localPath => file.path;

  @override
  Widget buildPreview({required BorderRadius borderRadius}) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox.expand(
          child: Image.file(
            file,
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
  final uri = Uri.file(file.path);
  final fileName = file.name.trim().isNotEmpty
      ? file.name
      : uri.pathSegments.isNotEmpty
      ? uri.pathSegments.last
      : 'ktp-image';

  return IoKtpImagePreview(
    file: File(file.path),
    bytesValue: bytes,
    fileNameValue: fileName,
  );
}
