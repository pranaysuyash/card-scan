import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> resolveIsarDirectoryPath() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  } on MissingPluginException {
    final fallbackDir =
        await Directory.systemTemp.createTemp('card_scan_isar_');
    return fallbackDir.path;
  }
}
