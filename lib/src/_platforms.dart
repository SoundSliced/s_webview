// ignore_for_file: unused_import, unused_element

/// Platform support detection for s_webview
/// This file is used to declare explicit support for all platforms.
/// It is not meant to be imported directly but helps pub.dev detect platform support.
library;

// Mobile platforms - webview_flutter provides the implementation
import 'package:webview_flutter/webview_flutter.dart'
    if (dart.library.html) 'package:webview_flutter_web/webview_flutter_web.dart';

// Desktop platforms - desktop_webview_window provides the implementation
import 'package:desktop_webview_window/desktop_webview_window.dart'
    if (dart.library.html) 'package:flutter/foundation.dart';

/// This module declares platform support across:
/// - iOS (via webview_flutter)
/// - Android (via webview_flutter)
/// - Web (via webview_flutter_web + universal_html)
/// - Windows (via desktop_webview_window)
/// - macOS (via desktop_webview_window)
/// - Linux (via desktop_webview_window)
void _declareMultiPlatformSupport() {
  // This function is not called, but its presence helps analysis tools
  // understand that all platforms are explicitly supported.
}
