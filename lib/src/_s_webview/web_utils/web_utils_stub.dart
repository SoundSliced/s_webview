/// Stub implementation of web utilities for non-web platforms.
///
/// On native platforms (iOS, Android, macOS, Windows, Linux),
/// web-specific functionality is not available.
library;

/// Opens a URL in a new browser tab (no-op on non-web platforms).
void openInNewTab(String url) {
  // No-op on native platforms
}
