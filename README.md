# s_webview

A robust, cross-platform WebView widget for Flutter that provides a seamless browsing experience with built-in loading states, error handling, and smooth animations.

![Demo](https://raw.githubusercontent.com/SoundSliced/s_webview/main/example/assets/example.gif)

## Features

*   **Cross-Platform Support**: Works on iOS, Android, Web, Windows, macOS, and Linux.
*   **Smooth Animations**: Features fade-in transitions for a polished user experience.
*   **Smart Loading State**: Displays a ticker-free circular progress indicator while content loads.
*   **Error Handling**: Gracefully handles load errors with user-friendly messages.
*   **Dynamic URL Updates**: Automatically reloads content when the URL changes.
*   **Web Optimization**: Includes specific fixes for Web proxy handling to prevent freezing and ensure correct resource loading.
    *   *Note: Proxy features are only needed and used on Flutter Web to bypass CORS and X-Frame-Options restrictions. Native platforms (Mobile & Desktop) use native WebViews and load all content directly.*

## Installation

Add `s_webview` to your `pubspec.yaml`:

```yaml
dependencies:
  s_webview: ^3.1.0
```

## Platform Requirements

### iOS
- **Minimum Version**: iOS 11.0 or higher
- **Setup**: No additional configuration needed. The package uses Flutter's built-in `webview_flutter` plugin
- **Dependencies**: Handled automatically by `webview_flutter` package

### Android
- **Minimum Version**: Android 4.4 (API level 19) or higher
- **Setup**: No additional configuration needed. The package uses Flutter's built-in `webview_flutter` plugin
- **Permissions**: Internet permission is automatically added to `AndroidManifest.xml` by Flutter
- **Dependencies**: Handled automatically by `webview_flutter` package

### Web
- **Browser Support**: All modern browsers (Chrome, Firefox, Safari, Edge)
- **Features**: 
  - Automatic CORS proxy detection and application
  - Configurable proxy URLs via `corsProxyUrls` parameter
  - Auto-detection of X-Frame-Options and CSP restrictions
- **Dependencies**: Handled automatically by `webview_flutter_web` package

### Windows
- **Minimum Version**: Windows 7 or higher6
- **Requirements**: 
  - **WebView2 Runtime** must be installed ([Download here](https://developer.microsoft.com/en-us/microsoft-edge/webview2/))
  - Visual C++ Redistributable (usually pre-installed on modern Windows)
- **Setup**: Users must install WebView2 Runtime if not already present
- **Note**: The package will throw an error if WebView2 runtime is not available

### macOS
- **Minimum Version**: macOS 10.10 or higher
- **Setup**: 
  - Requires Xcode command line tools
  - Ensure your Flutter/Xcode project includes the WebKit framework (handled by Flutter by default)
  - May require adding WebKit capability in Xcode signing
- **Dependencies**: Uses native WKWebView (built-in to macOS)

### Linux
- **Minimum Version**: Any modern Linux distribution with GTK 3.0+
- **Requirements**: WebKitGTK libraries must be installed
- **Installation**:
  - **Ubuntu/Debian**: 
    ```bash
    sudo apt-get install libwebkit2gtk-4.0-dev
    # or for newer versions:
    sudo apt-get install libwebkit2gtk-4.1-dev
    ```
  - **Fedora/RHEL**: 
    ```bash
    sudo dnf install webkit2-gtk3-devel
    ```
  - **Arch Linux**: 
    ```bash
    sudo pacman -S webkit2gtk
    ```
- **Note**: Without WebKitGTK installed, the app will fail to run on Linux

## Usage

### 1. Basic Usage

The simplest way to use `SWebView` is to provide a URL. It handles loading states and animations automatically.

```dart
import 'package:flutter/material.dart';
import 'package:s_webview/s_webview.dart';

class SimpleWebView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple WebView')),
      body: SWebView(
        url: 'https://flutter.dev',
      ),
    );
  }
}
```

### 2. Advanced Usage (Dynamic URLs & Error Handling)

You can handle errors, listen for blocked iframes, and dynamically update the URL.

```dart
class AdvancedWebView extends StatefulWidget {
  @override
  _AdvancedWebViewState createState() => _AdvancedWebViewState();
}

class _AdvancedWebViewState extends State<AdvancedWebView> {
  String _currentUrl = 'https://flutter.dev';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Control Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _currentUrl = 'https://pub.dev'),
                child: Text('Load Pub.dev'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _currentUrl = 'https://google.com'),
                child: Text('Load Google'),
              ),
            ],
          ),
          // WebView
          Expanded(
            child: SWebView(
              url: _currentUrl,
              // Handle loading errors
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              },
              // Handle iframe blocking (Web specific)
              onIframeBlocked: () {
                print('Content blocked by browser policy');
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Web-Specific Usage (Proxy & Overlays)

Flutter Web has specific challenges like CORS, X-Frame-Options, and pointer event capturing by iframes. `SWebView` provides tools to handle these.

#### Handling Restricted Sites (CORS / X-Frame-Options)

Use `autoDetectFrameRestrictions` and `showToolbar` to help users access sites that normally block embedding (like Google or GitHub).

```dart
SWebView(
  url: 'https://github.com', // Normally blocked by X-Frame-Options
  
  // Automatically detects if proxy is needed and switches to it
  autoDetectFrameRestrictions: true, 
  
  // Shows a toolbar with "Retry with Proxy" and "Open in New Tab" buttons
  showToolbar: true, 
)
```

#### Handling Overlays (Pointer Interception)

On Web, iframes swallow all mouse clicks. If you stack a widget *over* the WebView, it won't be clickable unless you wrap it with `SWebView.tapTarget`.

```dart
Stack(
  children: [
    SWebView(url: 'https://flutter.dev'),
    
    // A floating button over the webview
    Positioned(
      bottom: 20,
      right: 20,
      // WRAPPER REQUIRED: Makes the button clickable on Web
      child: SWebView.tapTarget(
        child: FloatingActionButton(
          onPressed: () => print('Clicked!'),
          child: Icon(Icons.add),
        ),
      ),
    ),
  ],
)
```

## Platform Specifics

*   **Mobile (iOS/Android)**: Uses `webview_flutter` for native performance. No proxy required.
*   **Web**: Uses `webview_flutter_web` with custom proxy handling to support `X-Frame-Options` and CORS restrictions (e.g. loading Google, GitHub).
*   **Desktop (Windows/macOS/Linux)**: Uses a custom desktop implementation. No proxy required.

## License

MIT License - see the [LICENSE](LICENSE) file for details.

## Repository

https://github.com/SoundSliced/s_webview
