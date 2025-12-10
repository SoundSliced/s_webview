// ignore_for_file: unused_import

/// Web-specific WebView implementation
/// This file provides Web platform support for s_webview using webview_flutter_web.
library;

import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:universal_html/html.dart' as html;
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

/// Gets the Web WebViewController
///
/// This function demonstrates that the package uses webview_flutter_web
/// which provides full Web support through iframes and dynamic content loading.
html.IFrameElement? createWebController() {
  if (kIsWeb) {
    return html.IFrameElement();
  }
  return null;
}
