/// iOS-specific WebView implementation
/// This file provides iOS platform support for s_webview using webview_flutter.
library;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';

/// Initializes WebView for iOS platform
///
/// On iOS, webview_flutter provides native WebKit integration.
/// Users need:
/// - iOS 11.0 or higher
/// - wkwebview package (automatically handled by webview_flutter)
void initializeIOSWebView() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    // Initialization happens automatically when WebViewController is created
    debugPrint('iOS WebView initialized');
  }
}

/// Gets the iOS WebViewController
///
/// This function demonstrates that the package uses webview_flutter
/// which provides full iOS support through WKWebView.
WebViewController? createIOSController() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return WebViewController();
  }
  return null;
}
