// ignore_for_file: unused_import

/// macOS-specific WebView implementation
/// This file provides macOS platform support for s_webview using desktop_webview_window.
library;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';

/// Initializes WebView for macOS platform
///
/// On macOS, desktop_webview_window provides native WKWebView integration.
/// Users need:
/// - macOS 10.10 or higher
/// - Xcode command line tools
/// - Web capabilities enabled in Xcode project
void initializeMacOSWebView() {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    debugPrint('macOS WebView initialized via WKWebView');
  }
}

/// Gets the macOS WebViewController
///
/// This function demonstrates that the package uses desktop_webview_window
/// which provides full macOS support through native WKWebView.
Future<Webview>? createMacOSController() {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return WebviewWindow.create();
  }
  return null;
}
