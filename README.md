# s_webview

A Flutter package that provides an enhanced WebView widget with smooth animations and loading states.

## Features

- **Animated Loading**: Displays a smooth circular progress indicator while the web page loads
- **Error Handling**: Shows user-friendly error messages when URLs fail to load
- **Fade Animations**: Beautiful fade-in effects for loading and webview transitions
- **URL Updates**: Automatically reloads when the URL property changes
- **Cross-Platform**: Built on top of atomic_webview for reliable performance across platforms

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s_webview: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:s_webview/s_webview.dart';
```

Use the SWebView widget in your Flutter app:

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SWebView Example'),
      ),
      body: const Center(
        child: SWebView(url: 'https://flutter.dev'),
      ),
    );
  }
}
```

## Parameters

- `url`: The URL to load in the webview (defaults to 'https://flutter.dev')
- `key`: Optional widget key

## Example

See the `example/` directory for a complete working example that demonstrates the SWebView widget in action.

## Dependencies

This package uses:
- `atomic_webview`: For cross-platform webview functionality
- `flutter_animate`: For smooth animations
- `ticker_free_circular_progress_indicator`: For performance-optimized loading indicator

## License

MIT License - see LICENSE file for details.

## Repository

https://github.com/SoundSliced/mywebview

## Issues

Report issues and request features at: https://github.com/SoundSliced/mywebview/issues

## Repository

https://github.com/SoundSliced/s_webview
