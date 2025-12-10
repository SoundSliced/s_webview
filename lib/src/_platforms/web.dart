// ignore_for_file: unused_import

/// Web-specific WebView implementation
/// This file provides Web platform support for s_webview using webview_flutter_web.
library;

import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:flutter/foundation.dart';

/// Initializes WebView for Web platform
///
/// On Web, webview_flutter_web provides iframe-based WebView integration.
/// Users need:
/// - Any modern web browser (Chrome, Firefox, Safari, Edge)
/// - CORS proxy may be needed for cross-origin requests
void initializeWebView() {
  if (kIsWeb) {
    debugPrint('Web WebView initialized');
  }
}
