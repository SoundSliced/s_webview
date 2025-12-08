// A comprehensive WebView package for Flutter with multi-platform support.
//
// This package provides a unified API for displaying web content across
// all Flutter platforms: iOS, Android, Web, Windows, macOS, and Linux.
//
// ## Features
//
// * Multi-platform support with a single API
// * Desktop support via native webview
// * Mobile support via webview_flutter
// * Navigation controls (back, forward, reload)
// * JavaScript integration
// * Message passing between Dart and JavaScript
// * Custom title bar for desktop platforms
//
// ## Basic Usage

// ```dart
// import 'package:s_webview/_s_webview/lib/_s_webview.dart';
//
// class MyWebViewPage extends StatefulWidget {
//   @override
//   _MyWebViewPageState createState() => _MyWebViewPageState();
//
// ## Platform Requirements
//
// * **iOS**: iOS 11.0 or higher
// * **Android**: Android 4.4 (API 19) or higher
//   void initState() {
//     super.initState();
//     _initWebView();
//   }
//
//   Future<void> _initWebView() async {
//     await controller.init(
//       context: context,
//       setState: setState,
//       uri: Uri.parse('https://flutter.dev'),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: WebView(controller: controller),
//     );
//   }
// }
// ```
//
// ## Platform Requirements
//
// * **iOS**: iOS 11.0 or higher
// * **Android**: Android 4.4 (API 19) or higher
// * **Windows**: WebView2 Runtime must be installed
// * **macOS**: macOS 10.10 or higher
// * **Linux**: WebKitGTK must be installed
// * **Web**: All modern browsers
// library declaration intentionally omitted; lib/_s_webview.dart is a simple library file

export 'widget/widget.dart';
export 'webview_controller/webview_controller.dart';
