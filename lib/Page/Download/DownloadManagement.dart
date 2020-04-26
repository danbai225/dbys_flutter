import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DownloadManagement {
  static Map<String, String> nameMap = {};
  static List urlList = [];
  static int xz = 0;

  //与原生交互的通道
  static const platform = const MethodChannel('cn.p00q.dbys/M3U8Download');

  static init() async {
    platform.invokeMethod('Path', (await getExternalStorageDirectory()).path);
  }

  static add(String url, String pm, String jiName) {
    platform.invokeMethod(
        'Add', jsonEncode({"url": url, "pm": pm, "jiName": jiName}));
  }

  static cancel() {
    platform.invokeMethod('Cancel');
  }
}
