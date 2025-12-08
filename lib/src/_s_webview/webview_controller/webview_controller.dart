import 'dart:async';

import 'webview_controller_web.dart';

export 'webview_controller_web.dart';

/// Extension methods for [WebViewController] providing navigation control.
///
/// This extension adds synchronous and asynchronous navigation methods
/// for going back, forward, and loading new URLs.
extension WebViewControllerExtension on WebViewController {
  /// Navigates back in the WebView's history (synchronous version).
  ///
  /// This method will do nothing if the controller is not initialized.
  /// On mobile platforms, it delegates to the underlying mobile controller.
  /// Desktop platform support is not yet implemented.
  void goBackSync() {
    if (is_init == false) {
      return;
    }
    if (is_mobile) {
      webview_mobile_controller.goBack();
    }
    if (is_desktop) {
      unawaited(webview_desktop_controller.back());
    }
  }

  /// Navigates forward in the WebView's history (synchronous version).
  ///
  /// This method will do nothing if the controller is not initialized.
  /// On mobile platforms, it delegates to the underlying mobile controller.
  /// Desktop platform support is not yet implemented.
  void goForwardSync() {
    if (is_init == false) {
      return;
    }
    if (is_mobile) {
      webview_mobile_controller.goForward();
    }
    if (is_desktop) {
      unawaited(webview_desktop_controller.forward());
    }
  }

  /// Loads the specified [uri] in the WebView (synchronous version).
  ///
  /// This method will do nothing if the controller is not initialized.
  /// On mobile platforms, it delegates to the underlying mobile controller.
  /// Desktop platform support is not yet implemented.
  void goSync({
    required Uri uri,
  }) {
    if (is_init == false) {
      return;
    }
    if (is_mobile) {
      // Only apply custom headers if they were explicitly configured
      if (customHeaders.isNotEmpty) {
        webview_mobile_controller.loadRequest(uri, headers: customHeaders);
      } else {
        webview_mobile_controller.loadRequest(uri);
      }
    }
    if (is_desktop) {
      webview_desktop_controller.launch(uri.toString());
    }
  }

  /// Navigates back in the WebView's history (asynchronous version).
  ///
  /// Returns a [Future] that completes when the navigation is finished.
  /// This method will do nothing if the controller is not initialized.
  /// On mobile platforms, it delegates to the underlying mobile controller.
  /// Desktop platform support is not yet implemented.
  Future<void> goBack() async {
    if (is_init == false) {
      return;
    }
    if (is_mobile) {
      await webview_mobile_controller.goBack();
    }
    if (is_desktop) {
      await webview_desktop_controller.back();
    }
  }

  /// Navigates forward in the WebView's history (asynchronous version).
  ///
  /// Returns a [Future] that completes when the navigation is finished.
  /// This method will do nothing if the controller is not initialized.
  /// On mobile platforms, it delegates to the underlying mobile controller.
  /// Desktop platform support is not yet implemented.
  Future<void> goForward() async {
    if (is_init == false) {
      return;
    }
    if (is_mobile) {
      await webview_mobile_controller.goForward();
    }
    if (is_desktop) {
      await webview_desktop_controller.forward();
    }
  }

  /// Loads the specified [uri] in the WebView (asynchronous version).
  ///
  /// Returns a [Future] that completes when the navigation is finished.
  /// This method will do nothing if the controller is not initialized.
  /// On mobile platforms, it delegates to the underlying mobile controller.
  /// Desktop platform support is not yet implemented.
  Future<void> go({
    required Uri uri,
  }) async {
    if (is_init == false) {
      return;
    }
    if (is_mobile) {
      if (customHeaders.isNotEmpty) {
        await webview_mobile_controller.loadRequest(uri,
            headers: customHeaders);
      } else {
        await webview_mobile_controller.loadRequest(uri);
      }
    }
    if (is_desktop) {
      webview_desktop_controller.launch(uri.toString());
    }
  }
}
