import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import '../webview_controller/webview_controller.dart' as webview_controller;

/// A widget that displays a WebView.
///
/// This widget provides a unified interface for displaying web content
/// across different platforms (iOS, Android, Web, Windows, macOS, Linux).
///
/// The WebView will only be visible after the [controller] has been
/// initialized using [WebViewController.init].
///
/// Example usage:
/// ```dart
/// WebView(
///   controller: myWebViewController,
/// )
/// ```
class WebView extends StatelessWidget {
  /// The controller for this WebView instance.
  final webview_controller.WebViewController controller;

  /// Creates a WebView widget.
  ///
  /// The [controller] parameter must not be null and should be initialized
  /// before the widget is displayed.
  const WebView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.is_init) {
      return const SizedBox.shrink();
    }

    // Mobile platforms (Android, iOS, Web) use webview_flutter
    if (Platform.isAndroid || Platform.isIOS || kIsWeb) {
      return Visibility(
        visible: controller.is_init,
        replacement: const SizedBox.shrink(),
        child: webview_flutter.WebViewWidget(
          controller: controller.webview_mobile_controller,
        ),
      );
    }

    // Desktop platforms (Windows, macOS, Linux) use webview_window
    // The webview_window creates a native webview that displays the content
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // webview_window handles rendering natively; return a placeholder
      // that indicates the desktop webview is initialized and displaying
      return Visibility(
        visible: controller.is_init,
        replacement: const SizedBox.shrink(),
        child: Container(
          color: Colors.transparent,
          child: const SizedBox.expand(),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
