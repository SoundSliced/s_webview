import 'dart:io';

/// Configuration for creating a desktop WebView window.
///
/// This class provides options to customize the appearance and behavior
/// of desktop WebView windows on Windows, macOS, and Linux platforms.
class CreateConfiguration {
  /// The width of the WebView window in pixels.
  final int windowWidth;

  /// The height of the WebView window in pixels.
  final int windowHeight;

  /// The title of the window.
  final String title;

  /// The height of the title bar in pixels.
  final int titleBarHeight;

  /// The top padding for the title bar in pixels.
  ///
  /// This is typically used to account for platform-specific UI elements
  /// like the macOS traffic lights (close, minimize, maximize buttons).
  final int titleBarTopPadding;

  /// The user data folder path for Windows WebView2 runtime.
  ///
  /// This specifies where WebView2 stores its user data, cookies, and cache.
  final String userDataFolderWindows;

  /// Creates a configuration for a desktop WebView window.
  ///
  /// All parameters are optional and will use default values if not specified.
  const CreateConfiguration({
    this.windowWidth = 1280,
    this.windowHeight = 720,
    this.title = '',
    this.titleBarHeight = 40,
    this.titleBarTopPadding = 0,
    this.userDataFolderWindows = 'webview_window_WebView2',
  });

  /// Creates a platform-specific configuration with default values.
  ///
  /// This factory constructor automatically sets appropriate values
  /// for the current platform, such as adding top padding for the
  /// macOS title bar to account for the traffic light buttons.
  factory CreateConfiguration.platform() {
    return CreateConfiguration(
      titleBarTopPadding: Platform.isMacOS ? 24 : 0,
    );
  }

  /// Converts this configuration to a Map for platform channel communication.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'windowWidth': windowWidth,
        'windowHeight': windowHeight,
        'title': title,
        'titleBarHeight': titleBarHeight,
        'titleBarTopPadding': titleBarTopPadding,
        'userDataFolderWindows': userDataFolderWindows,
      };
}
