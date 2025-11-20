# SWebView Example App

This example demonstrates how to use the `s_webview` package in a Flutter application.

## Features Demonstrated

This example app showcases the following features of the SWebView package:

1. **Basic WebView Integration**: Loading web pages within a Flutter app
2. **Dynamic URL Switching**: Change the URL dynamically with smooth transitions
3. **Loading Animations**: Beautiful loading indicators while pages load
4. **Error Handling**: Graceful handling of loading failures
5. **Custom UI Integration**: Combining SWebView with Material Design components

## Running the Example

From the example directory, run:

```bash
flutter pub get
flutter run
```

Or from the root of the package:

```bash
cd example
flutter pub get
flutter run
```

## What's Included

### Main Features

- **Website Selector**: A popup menu in the app bar allows you to switch between different websites (Flutter, Dart, GitHub, Stack Overflow)
- **Current URL Display**: Shows the currently loaded URL in an info banner
- **Smooth Transitions**: Experience the fade animations when switching between URLs

### Code Highlights

The example demonstrates:

```dart
// Dynamic URL management
String currentUrl = 'https://flutter.dev';

// Switching URLs with setState
setState(() {
  currentUrl = newUrl;
});

// Using ValueKey to ensure proper widget rebuilding
SWebView(
  key: ValueKey(currentUrl),
  url: currentUrl,
)
```

## Learning Points

1. **State Management**: How to manage URL state in a StatefulWidget
2. **Widget Keys**: Using ValueKey to ensure proper widget rebuilding when URLs change
3. **Material Design**: Integrating SWebView with AppBar, PopupMenuButton, and other Material widgets
4. **Responsive Layout**: Using Column and Expanded to create a flexible layout

## Code Overview

The example app creates a Flutter application with:

- **Dynamic Website Switching**: Uses a PopupMenuButton to select from multiple predefined websites
- **URL Display**: Shows the currently loaded URL in an information banner
- **Responsive Layout**: Combines the info banner with the SWebView in a Column layout

The SWebView widget automatically handles:

- Displaying a loading indicator while the page loads
- Showing the web content with a smooth fade-in animation
- Handling any errors that might occur during loading
- Reloading when the URL changes

## Customization

Feel free to modify the example to:

- Add more websites to the list
- Customize the loading animations
- Add navigation buttons (back/forward)
- Implement a URL input field
- Add favorites functionality
- Change the theme and styling

You can modify the `url` parameter in the `SWebView` widget to load different websites:

```dart
SWebView(url: 'https://your-website.com')
```

## Learn More

For more information about the s_webview package, see the main [README.md](../README.md) file.
