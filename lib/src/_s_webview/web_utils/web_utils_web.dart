/// Web implementation of web utilities.
///
/// This file is only loaded on web platforms and provides
/// access to browser-specific functionality.
library;

import 'package:universal_html/html.dart' as html;

/// Opens a URL in a new browser tab (web platform only).
void openInNewTab(String url) {
  html.window.open(url, '_blank');
}
