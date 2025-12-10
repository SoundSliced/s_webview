/// Web implementation of web utilities.
///
/// This file is only loaded on web platforms and provides
/// access to browser-specific functionality.
///
/// Uses `package:web` for WASM compatibility instead of `dart:html`.
library;

import 'package:web/web.dart' as web;

/// Opens a URL in a new browser tab (web platform only).
void openInNewTab(String url) {
  web.window.open(url, '_blank');
}
