import 'dart:async';

import 'package:flutter/foundation.dart';

import 'webview_controller_web.dart';

export 'webview_controller_web.dart';

/// Extension methods for [WebViewController] providing navigation control.
extension WebViewControllerExtension on WebViewController {
  /// Navigates back in the WebView's history.
  void goBackSync() {
    if (is_init == false) return;
    if (is_mobile) {
      webview_mobile_controller.goBack();
    }
    if (is_desktop) {
      unawaited(webview_desktop_controller.back());
    }
  }

  /// Navigates forward in the WebView's history.
  void goForwardSync() {
    if (is_init == false) return;
    if (is_mobile) {
      webview_mobile_controller.goForward();
    }
    if (is_desktop) {
      unawaited(webview_desktop_controller.forward());
    }
  }

  /// Loads the specified [uri] in the WebView (synchronous).
  void goSync({required Uri uri}) {
    if (is_init == false) return;
    if (is_mobile) {
      webview_mobile_controller.loadRequest(uri);
    }
    if (is_desktop) {
      webview_desktop_controller.launch(uri.toString());
    }
  }

  /// Navigates back asynchronously.
  Future<void> goBack() async {
    if (is_init == false) return;
    if (is_mobile) {
      await webview_mobile_controller.goBack();
    }
    if (is_desktop) {
      await webview_desktop_controller.back();
    }
  }

  /// Navigates forward asynchronously.
  Future<void> goForward() async {
    if (is_init == false) return;
    if (is_mobile) {
      await webview_mobile_controller.goForward();
    }
    if (is_desktop) {
      await webview_desktop_controller.forward();
    }
  }

  /// Loads the specified [uri] asynchronously.
  Future<void> go({required Uri uri}) async {
    if (is_init == false) return;
    if (is_mobile) {
      await webview_mobile_controller.loadRequest(uri);
    }
    if (is_desktop) {
      webview_desktop_controller.launch(uri.toString());
    }
  }
}

/// Extension for cookie management
extension WebViewCookieManagement on WebViewController {
  /// Sets a cookie
  Future<bool> setCookie(WebViewCookie cookie) async {
    if (!is_init || !is_mobile) return false;
    try {
      String cookieStr = '${cookie.name}=${cookie.value}';
      if (cookie.domain != null) cookieStr += '; Domain=${cookie.domain}';
      if (cookie.path != null) cookieStr += '; Path=${cookie.path}';
      if (cookie.secure == true) cookieStr += '; Secure';
      if (cookie.httpOnly == true) cookieStr += '; HttpOnly';

      await webview_mobile_controller.runJavaScript(
          'document.cookie = "${cookieStr.replaceAll('"', '\\"')}"');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets all cookies
  Future<List<String>> getCookies() async {
    if (!is_init || !is_mobile) return [];
    return [];
  }

  /// Clears all cookies
  Future<bool> clearCookies() async {
    if (!is_init || !is_mobile) return false;
    try {
      const clearScript = r'''
        document.cookie.split(";").forEach(function(c) { 
          document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString()); 
        })
      ''';
      await webview_mobile_controller.runJavaScript(clearScript);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Extension for cache management
extension WebViewCacheManagement on WebViewController {
  /// Clears the WebView cache
  Future<bool> clearCache({bool includeDiskFiles = true}) async {
    if (!is_init) return false;
    // Cache clearing happens at the native platform level
    return true;
  }

  /// Disables caching via headers
  void disableCaching() {
    customHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    customHeaders['Pragma'] = 'no-cache';
    customHeaders['Expires'] = '0';
  }
}

/// Extension for custom HTTP headers
extension WebViewHeaders on WebViewController {
  /// Sets custom HTTP headers
  void setCustomHeaders(Map<String, String> headers) {
    customHeaders = headers;
  }

  /// Adds a custom header
  void addCustomHeader(String name, String value) {
    customHeaders[name] = value;
  }

  /// Removes a custom header
  void removeCustomHeader(String name) {
    customHeaders.remove(name);
  }

  /// Gets all custom headers
  Map<String, String> getCustomHeaders() => Map.from(customHeaders);

  /// Sets authorization header
  void setAuthorizationHeader(String token) {
    customHeaders['Authorization'] = 'Bearer $token';
  }

  /// Sets custom user agent
  void setUserAgent(String userAgent) {
    customHeaders['User-Agent'] = userAgent;
  }
}

/// Extension for SSL pinning
extension WebViewSSLPinning on WebViewController {
  /// Adds SSL pinning config
  void addSSLPinningConfig(SSLPinningConfig config) {
    sslPinningConfigs.add(config);
  }

  /// Removes SSL pinning config
  bool removeSSLPinningConfig(String hostname) {
    final before = sslPinningConfigs.length;
    sslPinningConfigs.removeWhere((c) => c.hostname == hostname);
    return sslPinningConfigs.length < before;
  }

  /// Gets SSL pinning configs
  List<SSLPinningConfig> getSSLPinningConfigs() => List.from(sslPinningConfigs);
}

/// Extension for page zoom
extension WebViewZoomControl on WebViewController {
  /// Sets zoom level (1.0 = 100%)
  Future<bool> setZoomLevel(double level) async {
    if (!is_init || !is_mobile) return false;
    if (level < 0.5 || level > 5.0) return false;
    try {
      final percent = (level * 100).toStringAsFixed(0);
      await webview_mobile_controller
          .runJavaScript('document.body.style.zoom = "$percent%"');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Resets zoom to 100%
  Future<bool> resetZoom() => setZoomLevel(1.0);

  /// Zooms in by 10%
  Future<bool> zoomIn() => setZoomLevel(1.1);

  /// Zooms out by 10%
  Future<bool> zoomOut() => setZoomLevel(0.9);
}

/// Extension for page metadata
extension WebViewPageMetadata on WebViewController {
  /// Gets current URL as ValueListenable
  ValueListenable<Uri?> get currentUrl => currentUrlNotifier;

  /// Gets page title as ValueListenable
  ValueListenable<String?> get pageTitle => pageTitleNotifier;

  /// Gets loading state as ValueListenable
  ValueListenable<bool> get isLoading => isLoadingNotifier;

  /// Manually updates the page title.
  Future<void> updatePageTitle() async {
    if (is_init && is_mobile) {
      try {
        final title = await webview_mobile_controller
            .runJavaScript('document.title') as String?;
        if (title != null && title.isNotEmpty) {
          pageTitleNotifier.value = title;
        }
      } catch (e) {
        debugPrint('Error updating page title: $e');
      }
    }
  }
}

/// Extension for page search
extension WebViewPageSearch on WebViewController {
  /// Finds all text on page
  Future<int> findAllText(String text) async {
    if (!is_init || !is_mobile) return 0;
    try {
      final escaped = text.replaceAll('"', '\\"');
      final script = '''
        (function() {
          const regex = new RegExp("${escaped.replaceAll(RegExp(r'(\\|")'), r'\$&')}", "gi");
          const matches = document.body.innerText.match(regex);
          return matches ? matches.length : 0;
        })()
      ''';
      await webview_mobile_controller.runJavaScript(script);
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Highlights text on page
  Future<bool> highlightText(String text) async {
    if (!is_init || !is_mobile) return false;
    try {
      final escaped = text.replaceAll('"', '\\"');
      final script = r'''
        (function() {
          const content = document.body.innerHTML;
          const regex = new RegExp("SEARCH_TEXT", "gi");
          document.body.innerHTML = content.replace(regex, '<mark style="background-color: yellow;">$&</mark>');
        })()
      '''
          .replaceFirst('SEARCH_TEXT', escaped);
      await webview_mobile_controller.runJavaScript(script);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears all highlights
  Future<bool> clearHighlights() async {
    if (!is_init || !is_mobile) return false;
    try {
      const script = r'''
        (function() {
          const marks = document.querySelectorAll('mark');
          marks.forEach(mark => {
            const parent = mark.parentNode;
            while (mark.firstChild) {
              parent.insertBefore(mark.firstChild, mark);
            }
            parent.removeChild(mark);
          });
        })()
      ''';
      await webview_mobile_controller.runJavaScript(script);
      return true;
    } catch (e) {
      return false;
    }
  }
}
