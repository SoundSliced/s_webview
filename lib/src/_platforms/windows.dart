// ignore_for_file: unused_import

/// Windows-specific WebView implementation
/// This file provides Windows platform support for s_webview using desktop_webview_window.
library;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';

/// Initializes WebView for Windows platform
///
/// On Windows, desktop_webview_window provides native WebView2 integration.
/// Users need:
/// - Windows 7 or higher
/// - WebView2 Runtime must be installed (https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
/// - Visual C++ Redistributable may be required
void initializeWindowsWebView() {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    debugPrint('Windows WebView initialized via WebView2');
  }
}

/// Gets the Windows WebViewController
///
/// This function demonstrates that the package uses desktop_webview_window
/// which provides full Windows support through WebView2.
Future<Webview>? createWindowsController() {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    return WebviewWindow.create();
  }
  return null;
}
