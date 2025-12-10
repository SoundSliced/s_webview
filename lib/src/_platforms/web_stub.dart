/// Stub implementation for web platform support.
///
/// This file is loaded on non-web platforms to avoid importing
/// web-specific packages like webview_flutter_web which depend on
/// dart:js_interop.
library;

/// Stub for web platform initialization.
void initializeWebView() {
  // No-op on non-web platforms
}
