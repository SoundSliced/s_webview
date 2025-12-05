# s_webview

A Flutter package that provides an enhanced WebView widget with smooth animations and loading states.

## Features

- **Animated Loading**: Displays a smooth circular progress indicator while the web page loads
- **Error Handling**: Shows user-friendly error messages when URLs fail to load
- **Fade Animations**: Beautiful fade-in effects for loading and webview transitions
- **URL Updates**: Automatically reloads when the URL property changes
- **Cross-Platform**: Built on top of atomic_webview for reliable performance across platforms
- **Performance Optimized**: Uses ticker-free circular progress indicator for better performance

## DEMO

![Demo](https://raw.githubusercontent.com/SoundSliced/s_webview/main/example/assets/example.gif)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  s_webview: ^1.0.4
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

Import the package:

```dart
import 'package:s_webview/s_webview.dart';
```

Use the SWebView widget in your Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:s_webview/s_webview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

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

### Advanced Usage - Dynamic URL Switching

The SWebView widget automatically handles URL changes. Here's an example that allows users to switch between different websites:

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentUrl = 'https://flutter.dev';

  final List<Map<String, String>> websites = [
    {'name': 'Flutter', 'url': 'https://flutter.dev'},
    {'name': 'Dart', 'url': 'https://dart.dev'},
    {'name': 'GitHub', 'url': 'https://github.com'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SWebView Example'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String url) {
              setState(() {
                currentUrl = url;
              });
            },
            itemBuilder: (BuildContext context) {
              return websites.map((website) {
                return PopupMenuItem<String>(
                  value: website['url'],
                  child: Text(website['name']!),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SWebView(
        key: ValueKey(currentUrl),
        url: currentUrl,
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

## Behavior

The SWebView widget provides the following behavior:

1. **Loading State**: When the webview is initializing, a circular progress indicator is displayed with a smooth fade-in animation (500ms)
2. **Error State**: If the URL fails to load, an error message is displayed
3. **Loaded State**: Once the webview successfully loads, it fades in with a 2.5-second animation using a custom easing curve
4. **Dynamic URL Updates**: When the `url` property changes, the widget automatically reloads the new URL with fresh loading animations

## Repository

https://github.com/SoundSliced/s_webview

## Issues

Report issues and request features at: https://github.com/SoundSliced/s_webview/issues
