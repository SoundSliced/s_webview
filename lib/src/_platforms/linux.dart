// ignore_for_file: unused_import

/// Linux-specific WebView implementation
/// This file provides Linux platform support for s_webview using desktop_webview_window.
library;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';

/// Initializes WebView for Linux platform
///
/// On Linux, desktop_webview_window provides native WebKitGTK integration.
/// Users need:
/// - Linux with GTK 3.0 or higher
/// - WebKitGTK libraries: libwebkit2gtk-4.0 or libwebkit2gtk-4.1
/// - Install: sudo apt-get install libwebkit2gtk-4.0-dev (Ubuntu/Debian)
/// - Install: sudo dnf install webkit2-gtk3-devel (Fedora)
void initializeLinuxWebView() {
  if (defaultTargetPlatform == TargetPlatform.linux) {
    debugPrint('Linux WebView initialized via WebKitGTK');
  }
}

/// Gets the Linux WebViewController
///
/// This function demonstrates that the package uses desktop_webview_window
/// which provides full Linux support through WebKitGTK.
Future<Webview>? createLinuxController() {
  if (defaultTargetPlatform == TargetPlatform.linux) {
    return WebviewWindow.create();
  }
  return null;
}
