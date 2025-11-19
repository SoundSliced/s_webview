import 'package:atomic_webview/webview_controller/webview_controller_web.dart';
// ignore: unused_import
import 'package:atomic_webview/widget/webview.dart' as atomic_webview;
import 'package:atomic_webview/widget/webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ticker_free_circular_progress_indicator/ticker_free_circular_progress_indicator.dart';

//************************************************** */
// NOTE: if atomic_webview package is no longer working,
// then use the webview_all package instead
// import 'package:webview_all/webview_all.dart';

//but beware that webview_all consumes way more memory
// and is not as performant as atomic_webview
//though it is stable and also works well on web
//************************************************** */

class MyWebView extends StatefulWidget {
  final String url;

  const MyWebView({super.key, this.url = "https://flutter.dev"});

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  WebViewController? webViewController;
  bool? isLoaded;

  @override
  void initState() {
    super.initState();
    initialisation();
  }

  Future<void> initialisation() async {
    try {
      webViewController = WebViewController();
      await webViewController!.init(
        context: context,
        uri: Uri.parse(widget.url),
        setState: (_) {
          if (mounted) {
            setState(() {
              isLoaded = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoaded = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(MyWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      // Reset the loading state
      setState(() {
        isLoaded = null;
      });
      // Reinitialize with the new URL
      initialisation();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoaded == null
        ? Center(child: TickerFreeCircularProgressIndicator())
            .animate(key: const ValueKey("loading"), effects: [
            FadeEffect(
              duration: Duration(seconds: 0, milliseconds: 500),
              curve: Curves.easeInOut,
            )
          ])
        : !isLoaded!
            ? const Center(child: Text("Failed to load URL"))
            : // If loaded, show the WebView
            WebView(
                controller: webViewController!,
              ).animate(key: ValueKey("myWebview - ${widget.url}"), effects: [
                FadeEffect(
                  duration: Duration(seconds: 2, milliseconds: 500),
                  curve: Curves.fastEaseInToSlowEaseOut,
                )
              ]);
  }
}

//********************************** */