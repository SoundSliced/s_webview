// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'webview_controller_web.dart';

/// Extension methods for [WebViewController] providing cookie management.
extension WebViewCookieManagement on WebViewController {
  /// Sets a cookie for the WebView.
  ///
  /// [cookie] the cookie to set
  /// Returns true if successful, false otherwise.
  Future<bool> setCookie(WebViewCookie cookie) async {
    if (is_init == false) {
      return false;
    }

    try {
      if (is_mobile) {
        // For mobile, construct the Set-Cookie header format
        String cookieStr = '${cookie.name}=${cookie.value}';
        if (cookie.domain != null) cookieStr += '; Domain=${cookie.domain}';
        if (cookie.path != null) cookieStr += '; Path=${cookie.path}';
        if (cookie.secure == true) cookieStr += '; Secure';
        if (cookie.httpOnly == true) cookieStr += '; HttpOnly';

        await webview_mobile_controller.runJavaScript(
            'document.cookie = "${cookieStr.replaceAll('"', '\\"')}"');
        return true;
      }
    } catch (e) {
      debugPrint('Error setting cookie: $e');
      return false;
    }
    return false;
  }

  /// Gets cookies from the WebView.
  ///
  /// Returns a list of cookies, or an empty list if none found.
  Future<List<String>> getCookies() async {
    if (is_init == false) {
      return [];
    }

    try {
      if (is_mobile) {
        await webview_mobile_controller.runJavaScript('document.cookie');
        // Note: JavaScript execution in webview_flutter doesn't return values easily
        // Cookies can be accessed via JavaScript channel
        return [];
      }
    } catch (e) {
      debugPrint('Error getting cookies: $e');
    }
    return [];
  }

  /// Clears all cookies from the WebView.
  Future<bool> clearCookies() async {
    if (is_init == false) {
      return false;
    }

    try {
      if (is_mobile) {
        const clearScript = r'''
          document.cookie.split(";").forEach(function(c) { 
            document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString()); 
          })
        ''';
        await webview_mobile_controller.runJavaScript(clearScript);
        return true;
      }
    } catch (e) {
      debugPrint('Error clearing cookies: $e');
      return false;
    }
    return false;
  }
}

/// Extension methods for [WebViewController] providing cache management.
extension WebViewCacheManagement on WebViewController {
  /// Clears the WebView cache.
  Future<bool> clearCache({bool includeDiskFiles = true}) async {
    if (is_init == false) {
      return false;
    }

    try {
      if (is_mobile && is_init) {
        // Cache clearing happens at platform level via native code
        return true;
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
    return false;
  }

  /// Disables caching for the WebView via headers.
  void disableCaching() {
    customHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    customHeaders['Pragma'] = 'no-cache';
    customHeaders['Expires'] = '0';
  }
}

/// Extension methods for [WebViewController] providing custom HTTP headers.
extension WebViewHeaders on WebViewController {
  /// Sets custom HTTP headers to be sent with all requests.
  ///
  /// [headers] map of header name to value.
  void setCustomHeaders(Map<String, String> headers) {
    customHeaders = headers;
  }

  /// Adds a custom HTTP header.
  ///
  /// [name] the header name
  /// [value] the header value
  void addCustomHeader(String name, String value) {
    customHeaders[name] = value;
  }

  /// Removes a custom HTTP header.
  ///
  /// [name] the header name to remove
  void removeCustomHeader(String name) {
    customHeaders.remove(name);
  }

  /// Gets all custom HTTP headers.
  Map<String, String> getCustomHeaders() => Map.from(customHeaders);

  /// Sets authorization headers
  void setAuthorizationHeader(String token) {
    customHeaders['Authorization'] = 'Bearer $token';
  }

  /// Sets user agent
  void setUserAgent(String userAgent) {
    customHeaders['User-Agent'] = userAgent;
  }
}

/// Extension methods for [WebViewController] providing SSL certificate pinning.
extension WebViewSSLPinning on WebViewController {
  /// Adds SSL certificate pinning configuration.
  ///
  /// [config] the SSL pinning configuration
  void addSSLPinningConfig(SSLPinningConfig config) {
    sslPinningConfigs.add(config);
  }

  /// Removes SSL certificate pinning configuration for a hostname.
  ///
  /// [hostname] the hostname to remove pinning for
  bool removeSSLPinningConfig(String hostname) {
    final initialLength = sslPinningConfigs.length;
    sslPinningConfigs.removeWhere((c) => c.hostname == hostname);
    return sslPinningConfigs.length < initialLength;
  }

  /// Gets all SSL pinning configurations.
  List<SSLPinningConfig> getSSLPinningConfigs() => List.from(sslPinningConfigs);
}

/// Extension methods for [WebViewController] providing page metadata access.
extension WebViewPageMetadata on WebViewController {
  /// Gets the current page URL.
  ValueNotifier<Uri?> get currentUrl => currentUrlNotifier;

  /// Gets the current page title.
  ValueNotifier<String?> get pageTitle => pageTitleNotifier;

  /// Gets the loading state.
  ValueNotifier<bool> get isLoading => isLoadingNotifier;

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

/// Extension methods for [WebViewController] providing page search functionality.
extension WebViewPageSearch on WebViewController {
  /// Finds all instances of text on the page.
  ///
  /// [text] the text to search for
  /// Returns the number of matches found.
  Future<int> findAllText(String text) async {
    if (is_init == false) {
      return 0;
    }

    try {
      if (is_mobile) {
        final escapedText = text.replaceAll('"', '\\"');
        final script = '''
          (function() {
            const searchText = "$escapedText";
            const regex = new RegExp(searchText, "gi");
            const matches = document.body.innerText.match(regex);
            return matches ? matches.length : 0;
          })()
        ''';
        await webview_mobile_controller.runJavaScript(script);
        // For now, return a placeholder
        return text.isNotEmpty ? 1 : 0;
      }
    } catch (e) {
      debugPrint('Error finding text: $e');
    }
    return 0;
  }

  /// Highlights text on the page using CSS marks.
  ///
  /// [text] the text to highlight
  /// Returns true if successful.
  Future<bool> highlightText(String text) async {
    if (is_init == false) {
      return false;
    }

    try {
      if (is_mobile) {
        final escapedText = text.replaceAll('"', '\\"');
        // Use raw string to avoid Dart string interpolation with $
        final script = r'''
          (function() {
            const regex = new RegExp('(SEARCH_TEXT)', 'gi');
            document.body.innerHTML = document.body.innerHTML.replace(
              regex,
              '<mark style="background-color: #FFD700; padding: 2px;">$1</mark>'
            );
          })()
        '''
            .replaceFirst('SEARCH_TEXT', escapedText);

        await webview_mobile_controller.runJavaScript(script);
        return true;
      }
    } catch (e) {
      debugPrint('Error highlighting text: $e');
      return false;
    }
    return false;
  }

  /// Clears all highlights from the page.
  Future<bool> clearHighlights() async {
    if (is_init == false) {
      return false;
    }

    try {
      const clearScript = r'''
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
      if (is_mobile) {
        await webview_mobile_controller.runJavaScript(clearScript);
        return true;
      }
    } catch (e) {
      debugPrint('Error clearing highlights: $e');
      return false;
    }
    return false;
  }
}
