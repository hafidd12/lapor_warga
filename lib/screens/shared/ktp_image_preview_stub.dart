import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ktp_image_preview_base.dart';

class UnsupportedKtpImagePreview extends KtpImagePreview {
  const UnsupportedKtpImagePreview();

  @override
  Uint8List get bytes => throw UnsupportedError('KTP preview is not supported.');

  @override
  String get fileName => 'ktp-image';

  @override
  String? get localPath => null;

  @override
  Widget buildPreview({required BorderRadius borderRadius}) {
    throw UnsupportedError('KTP preview is not supported.');
  }
}

Future<KtpImagePreview> createKtpImagePreviewFromXFile(XFile file) async {
  throw UnsupportedError('KTP preview is not supported.');
}
