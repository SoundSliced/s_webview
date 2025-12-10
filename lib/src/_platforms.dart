// ignore_for_file: unused_import, unused_element

/// Platform support detection for s_webview
/// This file imports all platform-specific implementations to ensure
/// pub.dev's static analyzer detects support for all platforms.
library;

// Import all platform implementations
export 'package:s_webview/src/_platforms/ios.dart';
export 'package:s_webview/src/_platforms/android.dart';
export 'package:s_webview/src/_platforms/web.dart';
export 'package:s_webview/src/_platforms/windows.dart';
export 'package:s_webview/src/_platforms/macos.dart';
export 'package:s_webview/src/_platforms/linux.dart';

/// This module declares explicit platform support for:
/// - iOS (via webview_flutter and WKWebView)
/// - Android (via webview_flutter and native Android WebView)
/// - Web (via webview_flutter_web and iframes)
/// - Windows (via desktop_webview_window and WebView2)
/// - macOS (via desktop_webview_window and WKWebView)
/// - Linux (via desktop_webview_window and WebKitGTK)
void _declarePlatformSupport() {
  // This function is not called, but helps analysis tools
}
