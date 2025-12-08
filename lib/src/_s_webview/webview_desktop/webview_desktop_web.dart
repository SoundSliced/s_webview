import 'package:flutter/material.dart';

class Webview {
  void setBrightness(Brightness brightness) {}
  void launch(String url) {}

  /// Web stub - not supported on web platform
  Future<void> back() async {}

  /// Web stub - not supported on web platform
  Future<void> forward() async {}

  /// Web stub - not supported on web platform
  void close() {}

  /// Web stub - not supported on web platform
  void addScriptToExecuteOnDocumentCreated(String javaScript) {}
}

class WebviewWindow {
  static Future<bool> isWebviewAvailable() async {
    return false;
  }

  static Future<Webview> create({CreateConfiguration? configuration}) async {
    return Webview();
  }
}

class CreateConfiguration {
  final double titleBarTopPadding;
  CreateConfiguration({
    required this.titleBarTopPadding,
  });
}
