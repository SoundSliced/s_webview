## 2.1.0

* Changed the `SWebView`'s build method to safely handle the case when webViewController is null (which happens on the first build before async initialization completes)
* ensured fixed Tests, and analysis issues, pub.dev's platform compatibility detection issues  
* updated documentations
* Now perfectly running as expected
* WASM compatibility:
  - Replaced universal_html with package:web, The official WASM-compatible package for browser APIs
  - universal_html uses dart:html internally which is NOT WASM-compatible
  - package:web (version 1.1.1) is the Dart team's official WASM-compatible replacement
  


## 2.0.8

* Fixed Tests failures due to dependencies import/export conflicts
      ✅ All 11 tests pass
      ✅ No analysis issues
* Fixed WASM issues: WASM compatibility improved with conditional imports

## 2.0.7

* **WASM Compatibility**: Fixed WASM compatibility by replacing `universal_io` with Flutter's `defaultTargetPlatform`
* Removed `universal_io` dependency (no longer needed)
* All platform detection now uses `defaultTargetPlatform` from `package:flutter/foundation.dart`
* Package is now fully compatible with Dart's WASM runtime for Web

## 2.0.6

* **Critical Fix**: Added federated plugin configuration to `pubspec.yaml` with `flutter.plugin.platforms` declaration
* This is the correct way for wrapper packages to declare platform support to pub.dev
* Added explicit platform package dependencies:
  - `webview_flutter_android` for Android
  - `webview_flutter_wkwebview` for iOS  
  - `webview_flutter_web` for Web
  - `desktop_webview_window` for Windows/macOS/Linux
* Platform configuration properly delegates to underlying platform implementations
* Formatted all platform-specific Dart files to pass static analysis

## 2.0.5

* **Major Fix**: Created proper platform-specific Dart files (`ios.dart`, `android.dart`, `web.dart`, `windows.dart`, `macos.dart`, `linux.dart`) that pub.dev can analyze
* Added explicit platform dependencies: `webview_flutter_android` for Android detection
* This enables pub.dev to correctly identify support for all 6 platforms through static analysis
* Platform detection now works for: iOS, Android, Web, Windows, macOS, and Linux

## 2.0.4

* Fixed pub.dev platform detection by adding explicit platform-specific imports for all supported platforms
* Added `_platforms.dart` with conditional imports for webview_flutter, webview_flutter_web, and desktop_webview_window
* Now correctly detected as supporting iOS, Android, Web, Windows, macOS, and Linux
* Added missing `universal_html` dependency to pubspec.yaml

## 2.0.3

* 2nd attempt at Fixing pub.dev's cross-platform compatibility checks, we shall see

## 2.0.2

* Fixed pub.dev's cross-platform compatibility checks, by removing certain conflicting dependencies

## 2.0.1

* Fixed platform support analysis on pub.dev by removing direct imports of platform-specific packages.
* Improved cross-platform compatibility checks.

## 2.0.0

* **New Features: - SPECIALLY on WEB PLATFORM**
  * (**Web-platform**) Added `SWebView.tapTarget` method to wrap widgets stacked over the WebView, making them tappable on Web (handles pointer interception).
  * (**Web-platform**) Added `showToolbar` parameter to display a built-in toolbar with "Retry with Proxy", "Clear Proxy Cache", and "Open in New Tab" buttons (Web only).
  * (**Web-platform**) Added `autoDetectFrameRestrictions` parameter to automatically detect X-Frame-Options and CSP restrictions and switch to proxy mode if needed.
  * (**Web-platform**) Added `corsProxyUrls` parameter to allow customization of the CORS proxies list.
  * Added static utility methods:
    * (**Web-platform**) `SWebView.retryWithProxy(url)`: Manually retry a URL using a CORS proxy.
    * `SWebView.openInNewTab(url)`: Open a URL in a new browser tab.
    * (**Web-platform**) `SWebView.removeFromCache(url)`: Remove a URL from the proxy cache.
    * `SWebView.getProxyCache()`: Get the current state of the proxy cache.
    * (**Web-platform**) `SWebView.isUrlInProxyCache(url)`: Check if a specific URL is cached.

* **Improvements:**
  * (**Web-platform**) **Persistent Caching:** Proxy settings and restriction detections are now saved to `SharedPreferences`, persisting across app restarts.
  * (**Web-platform**) **Smart Proxy Detection:** Intelligent detection logic that tests proxies to determine if a site (like Google or GitHub) requires a proxy, falling back to direct load if possible.
  * **Web Stability:** Fixed browser freezing issue on Web by injecting a `<base>` tag in proxied HTML to prevent infinite 404 loops for relative resources.
  * **Architecture:** Integrated `_s_webview` as an internal sub-package, removing external dependencies and allowing for tighter integration and fixes.
  * **Platform Support:** Full support for all platforms (iOS, Android, Web, Windows, macOS, Linux).
  * **Clarification:** Proxy features (CORS/X-Frame-Options handling) are **Web-only**. Native platforms (iOS, Android, Desktop) use native WebViews which do not suffer from these restrictions and load all websites correctly without proxies.

* **Fixes & Maintenance:**
  * Fixed missing type annotations throughout the codebase.
  * Fixed import path issues (converted absolute imports to relative imports).
  * Added comprehensive documentation to all public APIs.
  * Improved code quality and analysis score.
  * Enhanced WebView controller with better error handling.
  * Fixed WASM compatibility warnings.
  * Updated dependencies to latest stable versions.

## 1.0.4

* README updated

## 1.0.2

* Fixed repository URLs in pubspec.yaml to correctly reference s_webview instead of mywebview
* Updated all documentation to reflect correct repository links
* Improved package metadata for better pub.dev compatibility

## 1.0.1

* Updated documentation and examples
* Enhanced README with comprehensive usage examples
* Improved example app to demonstrate URL switching functionality
* Added more comprehensive test coverage
* Fixed repository references consistency
* Minor code documentation improvements

## 1.0.0

* Initial stable release
* Enhanced WebView widget with smooth animations and loading states
* Integrated with _s_webview for cross-platform webview support
* Added smooth fade-in animations using flutter_animate
* Included ticker-free circular progress indicator for loading state
* Support for URL changes with automatic reloading
* Error handling with user-friendly error messages
* Performance optimizations for better user experience

## 0.0.1

* Initial release of SWebView package
* Added SWebView widget with animated loading and error states
* Integrated with _s_webview for cross-platform webview support
* Added smooth fade-in animations using flutter_animate
* Included ticker-free circular progress indicator for loading state
* Support for URL changes with automatic reloading
