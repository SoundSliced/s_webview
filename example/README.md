# s_webview Example

This example demonstrates how to use the `s_webview` package in a Flutter application.

## Features Demonstrated

- Basic usage of the SWebView widget
- Loading a web page with smooth animations
- Handling loading and error states

## Running the Example

1. Navigate to the example directory:
```bash
cd example
```

2. Get the dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Code Overview

The example app creates a simple Flutter application that displays the Flutter.dev website using the SWebView widget. The widget automatically handles:

- Displaying a loading indicator while the page loads
- Showing the web content with a smooth fade-in animation
- Handling any errors that might occur during loading

## Customization

You can modify the `url` parameter in the `SWebView` widget to load different websites:

```dart
SWebView(url: 'https://your-website.com')
```
