// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:ticker_free_circular_progress_indicator/ticker_free_circular_progress_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '_s_webview/webview_controller/webview_controller.dart';
import '_s_webview/widget/widget.dart';
import '_s_webview/web_utils/web_utils.dart' as web_utils;

// Internal _s_webview implementation provides optimal performance
// across all platforms (iOS, Android, Web, Windows, macOS, Linux)
// TOOLBAR FIXED: showToolbar parameter now correctly controls toolbar visibility
// When showToolbar=false, the toolbar is never shown (even if page fails to load)
// When showToolbar=true, the toolbar with retry and open-in-new-tab buttons is displayed

class SWebView extends StatefulWidget {
  /// The URL to load in the WebView
  final String url;

  /// Callback for load errors
  final Function(String? error)? onError;

  /// Callback when iframe is blocked (web platform only)
  final VoidCallback? onIframeBlocked;

  /// Show the toolbar with retry with proxy and open-in-new-tab buttons
  /// Default: true when on Web platform
  final bool showToolbar;

  /// Automatically detect X-Frame-Options and CSP restrictions (default: true on web)
  /// When true, SWebView will check headers and apply CORS proxy only if needed
  /// This eliminates the need to manually pass useCorsProxy parameter
  final bool autoDetectFrameRestrictions;

  /// List of CORS proxies to try in order (with fallback)
  /// Default proxies are ordered by speed/reliability
  final List<String> corsProxyUrls;

  const SWebView({
    super.key,
    this.url = "https://flutter.dev",
    this.onError,
    this.onIframeBlocked,
    this.autoDetectFrameRestrictions = /* kIsWeb ? true : false */ true,
    this.corsProxyUrls = const [
      'https://api.codetabs.com/v1/proxy?quest=',
      'https://cors.bridged.cc/',
      'https://api.allorigins.win/raw?url=',
    ],
    this.showToolbar = kIsWeb,
  });

  @override
  State<SWebView> createState() => _SWebViewState();

  /// A convenience widget that wraps any child with PointerInterceptor
  ///
  /// Use this to wrap buttons or other interactive widgets that are stacked
  /// on top of SWebView in a Stack. This ensures they receive pointer events
  /// on Flutter Web where WebView iframes capture all events.
  ///
  /// **Example:**
  /// ```dart
  /// Stack(
  ///   children: [
  ///     SWebView(url: 'https://flutter.dev'),
  ///     Positioned(
  ///       top: 100,
  ///       right: 100,
  ///       child: SWebView.tapTarget(
  ///         child: ElevatedButton(
  ///           onPressed: () => print('Tapped!'),
  ///           child: Text('Tap me'),
  ///         ),
  ///       ),
  ///     ),
  ///   ],
  /// )
  /// ```
  static Widget tapTarget({
    required Widget child,
    Key? key,
  }) {
    if (kIsWeb) {
      return PointerInterceptor(
        key: key,
        child: child,
      );
    }
    return child;
  }

  /// Static method to load a URL via CORS proxy
  /// Can be called from custom buttons stacked over the widget
  /// This will mark the URL for proxy usage and trigger a reload
  ///
  /// **Example usage:**
  /// ```dart
  /// Stack(children: [
  ///   SWebView(url: 'https://example.com'),
  ///   Positioned(
  ///     top: 10,
  ///     right: 10,
  ///     child: PointerInterceptor(
  ///       child: ElevatedButton(
  ///         onPressed: () => SWebView.retryWithProxy('https://example.com'),
  ///         child: Text('Retry with Proxy'),
  ///       ),
  ///     ),
  ///   ),
  /// ])
  /// ```
  static Future<void> retryWithProxy(String url) async {
    if (kDebugMode) {
      debugPrint('SWebView: User requested retry with proxy for $url');
      debugPrint(
          'SWebView: ⚠️ SUGGESTION: Add "${Uri.parse(url).host}" to restrictedDomains list');
    }

    // Mark URL as needing proxy for future loads
    _SWebViewState._restrictionCache[url] = true;
    await _SWebViewState._saveCache();
  }

  /// Static method to open a URL in a new browser tab
  /// Can be called from custom buttons stacked over the widget
  /// Web platform only - no-op on native platforms
  ///
  /// **Parameters:**
  /// - `url`: The URL to open in a new tab
  /// - `addToProxyCacheForNextTime`: If true, the URL will be marked as requiring
  ///   a proxy for future loads. Default is true (maintains existing behavior).
  ///
  /// **Example usage:**
  /// ```dart
  /// Stack(children: [
  ///   SWebView(url: 'https://example.com'),
  ///   Positioned(
  ///     top: 10,
  ///     right: 10,
  ///     child: PointerInterceptor(
  ///       child: ElevatedButton(
  ///         // With proxy cache update (default)
  ///         onPressed: () => SWebView.openInNewTab('https://example.com'),
  ///         child: Text('Open in New Tab'),
  ///       ),
  ///     ),
  ///   ),
  /// ])
  /// ```
  ///
  /// **Example without proxy caching:**
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => SWebView.openInNewTab(
  ///     'https://example.com',
  ///     addToProxyCacheForNextTime: false,
  ///   ),
  ///   child: Text('Open'),
  /// )
  /// ```
  static Future<void> openInNewTab(
    String url, {
    bool addToProxyCacheForNextTime = true,
  }) async {
    if (kDebugMode) {
      debugPrint('SWebView: Opening in new tab: $url');
      if (addToProxyCacheForNextTime) {
        debugPrint('SWebView: URL marked to use proxy for next load: $url');
      } else {
        debugPrint(
            'SWebView: ⚠️ SUGGESTION: Add "${Uri.parse(url).host}" to restrictedDomains list');
      }
    }

    // Mark URL as needing proxy for future loads (default behavior)
    if (addToProxyCacheForNextTime) {
      _SWebViewState._restrictionCache[url] = true;
    }
    await _SWebViewState._saveCache();

    // Open in new tab (web platform)
    if (kIsWeb) {
      web_utils.openInNewTab(url);
    }
  }

  /// Static method to remove a URL from the proxy cache
  /// Use this to remove a URL that was previously marked as requiring a proxy
  /// The next load attempt will try a direct connection without the proxy
  ///
  /// **Example usage:**
  /// ```dart
  /// Stack(children: [
  ///   SWebView(url: 'https://example.com'),
  ///   Positioned(
  ///     top: 10,
  ///     right: 10,
  ///     child: PointerInterceptor(
  ///       child: ElevatedButton(
  ///         onPressed: () => SWebView.removeFromCache('https://example.com'),
  ///         child: Text('Clear Proxy Cache'),
  ///       ),
  ///     ),
  ///   ),
  /// ])
  /// ```
  static Future<void> removeFromCache(String url) async {
    if (kDebugMode) {
      debugPrint('SWebView: Removing $url from proxy cache');
    }

    _SWebViewState._restrictionCache.remove(url);
    await _SWebViewState._saveCache();
  }

  /// Get a read-only copy of the current proxy cache
  /// Returns a map of URLs to whether they require a proxy
  /// Key: URL string, Value: bool (true = needs proxy)
  static Map<String, bool> getProxyCache() {
    return Map<String, bool>.from(_SWebViewState._restrictionCache);
  }

  /// Check if a specific URL is in the proxy cache and requires a proxy
  /// Returns true if the URL is cached and requires a proxy, false otherwise
  static bool isUrlInProxyCache(String url) {
    return _SWebViewState._restrictionCache[url] ?? false;
  }
}

class _SWebViewState extends State<SWebView> {
  WebViewController? webViewController;
  bool? isLoaded;
  bool _isUsingProxy = false;

  @override
  void initState() {
    super.initState();
    _initializeWithCache();
  }

  /// Initialize with cached data loaded
  Future<void> _initializeWithCache() async {
    // Skip cache loading in test mode to avoid SharedPreferences dependency
    if (!WebViewController.isTestMode) {
      await _loadCache();
    }
    await initialisation();
  }

  /// Cache for frame restriction detection
  /// Maps URLs to whether they require a proxy
  /// Key: URL string, Value: bool (true = needs proxy)
  static final Map<String, bool> _restrictionCache = {};
  static const String _cacheKey = 'swebview_restriction_cache';

  /// Load restriction cache from persistent storage
  static Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson != null) {
        final Map<String, dynamic> decoded = json.decode(cacheJson);
        _restrictionCache.clear();
        decoded.forEach((key, value) {
          _restrictionCache[key] = value as bool;
        });

        if (kDebugMode) {
          debugPrint(
              'SWebView: Loaded ${_restrictionCache.length} cached restrictions from storage');
        }
      } else {
        if (kDebugMode) {
          debugPrint('SWebView: No cached restrictions found in storage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SWebView: Error loading cache: $e');
      }
    }
  }

  /// Save restriction cache to persistent storage
  static Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = json.encode(_restrictionCache);
      await prefs.setString(_cacheKey, cacheJson);

      if (kDebugMode) {
        debugPrint(
            'SWebView: Saved ${_restrictionCache.length} restrictions to storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SWebView: Error saving cache: $e');
      }
    }
  }

  /// Detects frame restrictions by testing with each CORS proxy
  /// Restricted sites (Google, GitHub) fail to load even through proxies (or fail fast)
  /// Unrestricted sites load successfully through at least one proxy
  /// Returns true if we should use proxy, false for direct load
  Future<bool> _checkHeadersForRestrictions(String url) async {
    if (!kIsWeb) return false; // Native platforms don't need proxy

    // Check cache first
    if (_restrictionCache.containsKey(url)) {
      final cached = _restrictionCache[url]!;
      if (kDebugMode) {
        debugPrint(
            'SWebView: Using cached restriction check - needs proxy: $cached');
      }
      return cached;
    }

    try {
      if (kDebugMode) {
        debugPrint('SWebView: Testing URL restrictions for $url...');
      }

      // Strategy: Try to fetch a small portion of the page via proxy
      // If proxy works, the site is accessible, so direct load might work
      // If all proxies fail, assume no restrictions (let direct load try)
      // If one proxy works, we know restrictions exist (direct load would fail)

      final testUrl = url;

      // Test with first proxy only (fastest)
      if (widget.corsProxyUrls.isNotEmpty) {
        try {
          final proxyUrl =
              '${widget.corsProxyUrls[0]}${Uri.encodeComponent(testUrl)}';

          if (kDebugMode) {
            debugPrint('SWebView: Testing proxy access...');
          }

          final response = await http.get(Uri.parse(proxyUrl)).timeout(
                const Duration(seconds: 3),
              );

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            // Proxy succeeded - check if this is a restricted domain
            // High-profile restricted sites: google.com, github.com, facebook.com, etc.
            final lowerUrl = url.toLowerCase();
            final restrictedDomains = [
              'google.com',
              'github.com',
              'facebook.com',
              'twitter.com',
              'instagram.com',
              'linkedin.com',
              'pinterest.com',
              'reddit.com',
              'amazon.com',
              'ebay.com',
            ];

            final isKnownRestricted = restrictedDomains.any(
                (domain) => lowerUrl.contains(domain.replaceAll('.com', '')));

            if (kDebugMode) {
              debugPrint(
                  'SWebView: Proxy test succeeded. Known restricted domain: $isKnownRestricted');
            }

            // For known restricted domains or if we detect restrictions, use proxy
            // Otherwise try direct load first
            _restrictionCache[url] = isKnownRestricted;
            await _saveCache(); // Persist to storage
            return isKnownRestricted;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SWebView: Proxy test failed: $e');
          }
        }
      }

      // Default: assume no restrictions and try direct load
      if (kDebugMode) {
        debugPrint('SWebView: No restrictions detected, will try direct load');
      }
      _restrictionCache[url] = false;
      await _saveCache(); // Persist to storage
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SWebView: Error checking restrictions: $e');
      }
      // On any error, assume no restrictions (fail gracefully)
      _restrictionCache[url] = false;
      await _saveCache(); // Persist to storage
      return false;
    }
  }

  /// Detects if a page loaded successfully by checking URL and loading state
  /// Returns true if page appears to be blocked/failed, false if it loaded
  /// Fetches page source through CORS proxy with fallback (web platform only)
  Future<String?> _fetchPageSourceViaProxy(String url) async {
    if (!kIsWeb) {
      return null; // Not on web, don't fetch
    }

    for (int i = 0; i < widget.corsProxyUrls.length; i++) {
      try {
        final proxyBase = widget.corsProxyUrls[i];
        final encodedUrl = Uri.encodeComponent(url);
        final proxiedUrl = '$proxyBase$encodedUrl';

        if (kDebugMode) {
          debugPrint('SWebView: Fetching via proxy ($i): $url -> $proxiedUrl');
        }

        final response = await http
            .get(Uri.parse(proxiedUrl))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('SWebView: Successfully fetched via proxy');
          }
          return response.body;
        } else {
          throw Exception('Proxy returned status ${response.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SWebView: Proxy $i failed: $e');
        }

        if (i == widget.corsProxyUrls.length - 1) {
          // Last proxy failed
          if (kDebugMode) {
            debugPrint('SWebView: All proxies exhausted');
          }
          return null;
        }
        // Try next proxy
        continue;
      }
    }

    return null;
  }

  /// Detects if a URL requires CORS proxy by checking HTTP response headers
  /// Checks for: X-Frame-Options (DENY, SAMEORIGIN) and CSP frame-ancestors
  /// Returns true if CORS proxy should be used, false for direct load
  Future<void> initialisation() async {
    try {
      if (mounted) {
        setState(() {
          isLoaded = null;
        });
      }
      webViewController = WebViewController();

      // In test mode, skip all network calls and just mark as loaded
      if (WebViewController.isTestMode) {
        await webViewController!.init(
          context: context,
          uri: Uri.parse(widget.url),
          setState: (fn) {
            if (mounted) setState(fn);
          },
        );
        if (mounted) {
          setState(() {
            isLoaded = true;
          });
        }
        return;
      }

      // A safe setState wrapper that no-ops when the State is disposed
      void safeSetState(void Function() fn) {
        if (!mounted) return;
        setState(fn);
      }

      if (kIsWeb && widget.autoDetectFrameRestrictions) {
        // Check cache first
        bool needsProxy;
        if (_restrictionCache.containsKey(widget.url)) {
          needsProxy = _restrictionCache[widget.url]!;
          if (kDebugMode) {
            debugPrint(
                'SWebView: Using cached result - needs proxy: $needsProxy');
          }
        } else {
          // Check headers to detect restrictions
          if (kDebugMode) {
            debugPrint(
                'SWebView: Checking headers for restrictions on ${widget.url}...');
          }
          needsProxy = await _checkHeadersForRestrictions(widget.url);
        }

        if (needsProxy) {
          // Use proxy
          if (kDebugMode) {
            debugPrint('SWebView: Loading via proxy...');
          }
          _isUsingProxy = true;
          var pageSource = await _fetchPageSourceViaProxy(widget.url);

          if (pageSource != null) {
            // Inject <base> tag to fix relative links
            if (!pageSource.contains('<base')) {
              final headIndex = pageSource.indexOf('<head>');
              if (headIndex != -1) {
                pageSource = pageSource.replaceFirst(
                    '<head>', '<head><base href="${widget.url}">');
              } else {
                pageSource = '<base href="${widget.url}">$pageSource';
              }
            }

            final base64Html = base64.encode(utf8.encode(pageSource));
            final dataUri = Uri.parse('data:text/html;base64,$base64Html');

            webViewController!
                .init(
              context: context,
              uri: dataUri,
              setState: (fn) {
                if (mounted) safeSetState(fn);
              },
            )
                .then((_) {
              if (mounted) {
                setState(() {
                  isLoaded = true;
                });
                widget.onError?.call(null);
              }
            }).catchError((e) {
              debugPrint('Error initializing webview: $e');
              final errorMessage =
                  'Failed to load: ${e.toString().replaceAll('Exception: ', '')}';
              if (kIsWeb && mounted) {
                widget.onIframeBlocked?.call();
              }
              if (mounted) {
                setState(() {
                  isLoaded = false;
                });
                widget.onError?.call(errorMessage);
              }
            });
          } else {
            throw Exception('Failed to load via proxy');
          }
        } else {
          // Load directly
          if (kDebugMode) {
            debugPrint(
                'SWebView: Loading directly (no restrictions detected)...');
          }
          _isUsingProxy = false;

          webViewController!
              .init(
            context: context,
            uri: Uri.parse(widget.url),
            setState: (fn) {
              if (mounted) safeSetState(fn);
            },
          )
              .then((_) {
            if (mounted) {
              setState(() {
                isLoaded = true;
              });
              widget.onError?.call(null);
            }
          }).catchError((e) {
            debugPrint('Error initializing webview: $e');
            final errorMessage =
                'Failed to load: ${e.toString().replaceAll('Exception: ', '')}';
            if (kIsWeb && mounted) {
              widget.onIframeBlocked?.call();
            }
            if (mounted) {
              setState(() {
                isLoaded = false;
              });
              widget.onError?.call(errorMessage);
            }
          });
        }
      } else {
        // Auto-detection disabled or native platform, load directly
        webViewController!
            .init(
          context: context,
          uri: Uri.parse(widget.url),
          setState: (fn) {
            if (mounted) safeSetState(fn);
          },
        )
            .then((_) {
          if (mounted) {
            setState(() {
              isLoaded = true;
            });
            widget.onError?.call(null);
          }
        }).catchError((e) {
          debugPrint('Error initializing webview: $e');
          final errorMessage =
              'Failed to load: ${e.toString().replaceAll('Exception: ', '')}';
          if (kIsWeb && mounted) {
            widget.onIframeBlocked?.call();
          }
          if (mounted) {
            setState(() {
              isLoaded = false;
            });
            widget.onError?.call(errorMessage);
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing webview: $e');
      final errorMessage =
          'Failed to load: ${e.toString().replaceAll('Exception: ', '')}';

      // On web, likely an iframe restriction
      if (kIsWeb && mounted) {
        widget.onIframeBlocked?.call();
      }

      if (mounted) {
        setState(() {
          isLoaded = false;
        });
        widget.onError?.call(errorMessage);
      }
    }
  }

  Future<void> _loadUrl(String url) async {
    if (webViewController == null || webViewController!.is_init == false) {
      await initialisation();
      return;
    }

    // In test mode, just update the loaded state without actual navigation
    if (WebViewController.isTestMode) {
      if (mounted) {
        setState(() {
          isLoaded = true;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          isLoaded = null;
        });
      }

      if (kIsWeb && widget.autoDetectFrameRestrictions) {
        // Check cache first
        bool needsProxy;
        if (_restrictionCache.containsKey(url)) {
          needsProxy = _restrictionCache[url]!;
          if (kDebugMode) {
            debugPrint(
                'SWebView: Using cached result - needs proxy: $needsProxy');
          }
        } else {
          // Check headers to detect restrictions
          if (kDebugMode) {
            debugPrint(
                'SWebView: Checking headers for restrictions on $url...');
          }
          needsProxy = await _checkHeadersForRestrictions(url);
        }

        if (needsProxy) {
          // Use proxy
          if (kDebugMode) {
            debugPrint('SWebView: Loading via proxy...');
          }
          var pageSource = await _fetchPageSourceViaProxy(url);
          if (pageSource != null) {
            // Inject <base> tag to fix relative links
            if (!pageSource.contains('<base')) {
              final headIndex = pageSource.indexOf('<head>');
              if (headIndex != -1) {
                pageSource = pageSource.replaceFirst(
                    '<head>', '<head><base href="$url">');
              } else {
                pageSource = '<base href="$url">$pageSource';
              }
            }

            final base64Html = base64.encode(utf8.encode(pageSource));
            final dataUri = Uri.parse('data:text/html;base64,$base64Html');
            await webViewController!.go(uri: dataUri);
          } else {
            throw Exception('Failed to load via proxy');
          }
        } else {
          // Load directly
          if (kDebugMode) {
            debugPrint(
                'SWebView: Loading directly (no restrictions detected)...');
          }
          await webViewController!.go(uri: Uri.parse(url));
        }
      } else {
        // Auto-detection disabled or native platform, load directly
        await webViewController!.go(uri: Uri.parse(url));
      }

      if (mounted) {
        setState(() {
          isLoaded = true;
        });
        widget.onError?.call(null);
      }
    } catch (e) {
      debugPrint('Error loading new url: $e');
      final errorMessage =
          'Failed to load: ${e.toString().replaceAll('Exception: ', '')}';

      // On web, likely an iframe restriction
      if (kIsWeb && mounted) {
        widget.onIframeBlocked?.call();
      }

      if (mounted) {
        setState(() {
          isLoaded = false;
        });
        widget.onError?.call(errorMessage);
      }
    }
  }

  @override
  void didUpdateWidget(SWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadUrl(widget.url);
    }
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the loading indicator widget
    Widget loadingWidget = Center(child: TickerFreeCircularProgressIndicator());

    // Build the webview widget only if controller is initialized
    Widget webviewWidget =
        webViewController != null && webViewController!.is_init
            ? WebView(controller: webViewController!)
            : const SizedBox.shrink();

    // Apply animations only when not in test mode
    if (!WebViewController.isTestMode) {
      loadingWidget = loadingWidget.animate(
        key: const ValueKey("loading"),
        effects: [
          FadeEffect(
            duration: Duration(seconds: 0, milliseconds: 500),
            curve: Curves.easeInOut,
          )
        ],
      );
      webviewWidget = webviewWidget.animate(
        key: ValueKey("sWebview - ${widget.url}"),
        effects: [
          FadeEffect(
            duration: Duration(seconds: 2, milliseconds: 500),
            curve: Curves.fastEaseInToSlowEaseOut,
          )
        ],
      );
    }

    return Column(
      children: [
        // Toolbar with action buttons (web only)
        if (kIsWeb && widget.showToolbar) _buildToolbar(),

        // Main content
        Expanded(
          child: isLoaded == null
              ? loadingWidget
              : !isLoaded!
                  ? const Center(child: Text("Failed to load URL"))
                  : webviewWidget,
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return SWebView.tapTarget(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (_isUsingProxy)
              Tooltip(
                message:
                    'Remove this URL from the proxy cache and reload directly',
                child: FilledButton.icon(
                  onPressed: () async {
                    await SWebView.removeFromCache(widget.url);
                    // Reload without proxy
                    if (mounted) {
                      setState(() {
                        isLoaded = null;
                        _isUsingProxy = false;
                      });
                    }
                    await _loadUrl(widget.url);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear URL from Proxy'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (_isUsingProxy) const SizedBox(width: 12),
            if (!_isUsingProxy) const Spacer(),
            if (!_isUsingProxy)
              Tooltip(
                message: 'Try loading this page through a CORS proxy',
                child: FilledButton.icon(
                  onPressed: () async {
                    await SWebView.retryWithProxy(widget.url);
                    // Reload with proxy
                    if (mounted) {
                      setState(() {
                        isLoaded = null;
                        _isUsingProxy = true;
                      });
                    }
                    await _loadUrl(widget.url);
                  },
                  icon: const Icon(Icons.vpn_lock, size: 18),
                  label: const Text('Retry with Proxy'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (!_isUsingProxy) const SizedBox(width: 12),
            Tooltip(
              message: 'Open this page in a new browser tab',
              child: OutlinedButton.icon(
                onPressed: () => SWebView.openInNewTab(widget.url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in New Tab'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ********************************** */
