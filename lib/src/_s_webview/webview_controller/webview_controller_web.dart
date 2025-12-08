// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_flutter_android;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'
    as webview_flutter_wkwebview;
import '../webview_desktop/webview_desktop.dart' as webview_desktop;

/// Cookie management data class
class WebViewCookie {
  final String name;
  final String value;
  final String? domain;
  final String? path;
  final DateTime? expires;
  final bool? httpOnly;
  final bool? secure;

  WebViewCookie({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expires,
    this.httpOnly,
    this.secure,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'value': value,
        'domain': domain,
        'path': path,
        'expires': expires?.millisecondsSinceEpoch,
        'httpOnly': httpOnly,
        'secure': secure,
      };
}

/// SSL Certificate pinning configuration
class SSLPinningConfig {
  final String hostname;
  final List<String> certificatePins; // Base64 encoded SHA256 hashes
  final bool allowBackupPin;

  SSLPinningConfig({
    required this.hostname,
    required this.certificatePins,
    this.allowBackupPin = true,
  });
}

/// A controller for managing WebView instances across different platforms.
///
/// This controller provides a unified API for WebView operations on both
/// mobile (iOS, Android, Web) and desktop (Windows, macOS, Linux) platforms.
///
/// Example usage:
/// ```dart
/// final controller = WebViewController();
/// await controller.init(
///   context: context,
///   setState: setState,
///   uri: Uri.parse('https://flutter.dev'),
/// );
/// ```
class WebViewController {
  /// The desktop webview controller instance.
  late final webview_desktop.Webview webview_desktop_controller;

  /// The mobile webview controller instance.
  late final webview_flutter.WebViewController webview_mobile_controller;

  /// Whether the controller has been initialized.
  bool is_init = false;

  /// Whether the current platform is desktop (Windows, macOS, Linux).
  final bool is_desktop =
      ((Platform.isLinux || Platform.isMacOS || Platform.isWindows) &&
          kIsWeb == false);

  /// Whether the current platform is mobile (iOS, Android, Web).
  final bool is_mobile = (Platform.isAndroid || Platform.isIOS || kIsWeb);

  /// Custom HTTP headers to be sent with requests
  Map<String, String> customHeaders = {};

  /// SSL pinning configuration
  List<SSLPinningConfig> sslPinningConfigs = [];

  /// Page metadata notifiers
  final ValueNotifier<Uri?> currentUrlNotifier = ValueNotifier<Uri?>(null);
  final ValueNotifier<String?> pageTitleNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  /// Request timeout duration (default 30 seconds)
  Duration requestTimeout = const Duration(seconds: 30);

  /// Custom User-Agent string
  String? customUserAgent;

  /// Whether to follow redirects (default true)
  bool followRedirects = true;

  /// Proxy URL (optional)
  String? proxyUrl;

  /// Cookie jar for storing and managing cookies
  final Map<String, Map<String, String>> _cookieJar = {};

  /// Creates a new WebViewController instance.
  WebViewController();

  /// Initializes the WebView controller with the provided configuration.
  ///
  /// [context] is the BuildContext for the widget.
  /// [setState] is a callback to update the parent widget's state.
  /// [uri] is the initial URL to load in the WebView.
  /// [customHeaders] optional custom HTTP headers to send with requests.
  /// [sslPinningConfigs] optional SSL certificate pinning configurations.
  /// [customUserAgent] optional custom User-Agent string for requests.
  /// [requestTimeout] timeout duration for requests (default 30 seconds).
  /// [followRedirects] whether to follow HTTP redirects (default true).
  /// [proxyUrl] optional proxy URL for network requests.
  Future<void> init({
    required BuildContext context,
    required void Function(void Function() fn) setState,
    required Uri uri,
    Map<String, String>? customHeaders,
    List<SSLPinningConfig>? sslPinningConfigs,
    String? customUserAgent,
    Duration? requestTimeout,
    bool? followRedirects,
    String? proxyUrl,
  }) async {
    // Only apply custom headers if explicitly provided
    this.customHeaders = customHeaders ?? {};
    this.sslPinningConfigs = sslPinningConfigs ?? [];
    this.customUserAgent = customUserAgent;
    this.requestTimeout = requestTimeout ?? const Duration(seconds: 30);
    this.followRedirects = followRedirects ?? true;
    this.proxyUrl = proxyUrl;

    if (is_mobile) {
      late final webview_flutter.PlatformWebViewControllerCreationParams params;
      if (webview_flutter.WebViewPlatform.instance
          is webview_flutter_wkwebview.WebKitWebViewPlatform) {
        params =
            webview_flutter_wkwebview.WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <webview_flutter_wkwebview
              .PlaybackMediaTypes>{},
        );
      } else {
        params =
            const webview_flutter.PlatformWebViewControllerCreationParams();
      }
      webview_mobile_controller =
          webview_flutter.WebViewController.fromPlatformCreationParams(params);
      setState(() {});
      if (!kIsWeb) {
        webview_mobile_controller
            .setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted);

        // Set custom User-Agent if provided
        if (customUserAgent != null) {
          webview_mobile_controller.setUserAgent(customUserAgent);
        }

        webview_mobile_controller.setNavigationDelegate(
          webview_flutter.NavigationDelegate(
            onProgress: (int progress) {
              isLoadingNotifier.value = progress < 100;
              debugPrint('WebView is loading (progress : $progress%)');
            },
            onPageStarted: (String url) {
              isLoadingNotifier.value = true;
              currentUrlNotifier.value = Uri.parse(url);
              debugPrint('Page started loading: $url');
            },
            onPageFinished: (String url) {
              isLoadingNotifier.value = false;
              currentUrlNotifier.value = Uri.parse(url);
              _updatePageTitle();
              debugPrint('Page finished loading: $url');
            },
            onWebResourceError: (webview_flutter.WebResourceError error) {
              isLoadingNotifier.value = false;
              debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            },
            onNavigationRequest: (webview_flutter.NavigationRequest request) {
              if (request.url.startsWith('https://www.youtube.com/')) {
                debugPrint('blocking navigation to ${request.url}');
                return webview_flutter.NavigationDecision.prevent;
              }
              debugPrint('allowing navigation to ${request.url}');
              return webview_flutter.NavigationDecision.navigate;
            },
          ),
        );
        webview_mobile_controller.addJavaScriptChannel(
          'Toaster',
          onMessageReceived: (webview_flutter.JavaScriptMessage message) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger == null) return; // Avoid calling on disposed context
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(SnackBar(content: Text(message.message)));
          },
        );
      }

      // Load URL with headers only if explicitly provided (to avoid blocking)
      if (this.customHeaders.isNotEmpty) {
        await webview_mobile_controller.loadRequest(
          uri,
          headers: this.customHeaders,
        );
      } else {
        await webview_mobile_controller.loadRequest(uri);
      }

      // #docregion platform_features
      if (webview_mobile_controller.platform
          is webview_flutter_android.AndroidWebViewController) {
        webview_flutter_android.AndroidWebViewController.enableDebugging(false);
        (webview_mobile_controller.platform
                as webview_flutter_android.AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }
      setState(() {});
      is_init = true;
    } else if (is_desktop) {
      final bool isWebviewAvailable =
          await webview_desktop.WebviewWindow.isWebviewAvailable();
      if (isWebviewAvailable) {
        final webview_desktop.Webview localWebviewController =
            await webview_desktop.WebviewWindow.create(
          configuration: webview_desktop.CreateConfiguration(
            titleBarTopPadding: Platform.isMacOS ? 20 : 0,
          ),
        );
        webview_desktop_controller = localWebviewController;
        webview_desktop_controller.setBrightness(Brightness.dark);
        webview_desktop_controller.launch(uri.toString());
        currentUrlNotifier.value = uri;
        setState(() {});
        is_init = true;
      } else {
        throw StateError(
          'Desktop WebView runtime is not available on this machine.',
        );
      }
    }
  }

  /// Updates page title from JavaScript evaluation
  Future<void> _updatePageTitle() async {
    if (is_mobile && is_init) {
      try {
        final String? title = await webview_mobile_controller
            .runJavaScript('document.title') as String?;
        if (title != null && title.isNotEmpty) {
          pageTitleNotifier.value = title;
        }
      } catch (e) {
        debugPrint('Error getting page title: $e');
      }
    }
  }

  /// Disposes platform resources associated with this controller.
  void dispose() {
    if (is_init == false) {
      return;
    }
    if (is_desktop) {
      try {
        webview_desktop_controller.close();
      } catch (e) {
        debugPrint('Error closing desktop webview: $e');
      }
    }
    currentUrlNotifier.dispose();
    pageTitleNotifier.dispose();
    isLoadingNotifier.dispose();
    _cookieJar.clear();
    is_init = false;
  }

  /// Sets a cookie for persistence across navigation
  void setCookie(String name, String value, {String? domain}) {
    final host = domain ?? currentUrlNotifier.value?.host ?? 'default';
    if (!_cookieJar.containsKey(host)) {
      _cookieJar[host] = {};
    }
    _cookieJar[host]![name] = value;
    debugPrint('Cookie set: $name=$value for domain $host');
  }

  /// Gets stored cookies for a domain
  Map<String, String> getCookies({String? domain}) {
    final host = domain ?? currentUrlNotifier.value?.host ?? 'default';
    return _cookieJar[host] ?? {};
  }

  /// Clears all stored cookies
  void clearCookies() {
    _cookieJar.clear();
    debugPrint('All cookies cleared');
  }
}
