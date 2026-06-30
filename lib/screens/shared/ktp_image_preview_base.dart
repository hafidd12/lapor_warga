import 'dart:typed_data';

import 'package:flutter/material.dart';

abstract class KtpImagePreview {
  const KtpImagePreview();

  Uint8List get bytes;

  String get fileName;

  String? get localPath;

  Widget buildPreview({required BorderRadius borderRadius});
}
