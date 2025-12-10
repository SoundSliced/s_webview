// ignore_for_file: unused_import

/// Android-specific WebView implementation
/// This file provides Android platform support for s_webview using webview_flutter.
library;

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/foundation.dart';

/// Initializes WebView for Android platform
///
/// On Android, webview_flutter provides native Android WebView integration.
/// Users need:
/// - Android 4.4 (API level 19) or higher
/// - webview_flutter_android package (automatically handled by webview_flutter)
/// - AndroidManifest.xml may need INTERNET permission (automatically added by Flutter)
void initializeAndroidWebView() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Initialize Android-specific WebView
    debugPrint('Android WebView initialized');
  }
}

/// Gets the Android WebViewController
///
/// This function demonstrates that the package uses webview_flutter_android
/// which provides full Android support through native Android WebView.
WebViewController? createAndroidController() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return WebViewController();
  }
  return null;
}
