import 'package:flutter_test/flutter_test.dart';
import 'package:s_webview/s_webview.dart';

void main() {
  group('SWebView Widget Tests', () {
    testWidgets('SWebView can be instantiated with default URL',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SWebView(),
          ),
        ),
      );

      // Pump and settle to complete all animations
      await tester.pumpAndSettle();

      expect(find.byType(SWebView), findsOneWidget);
    });

    testWidgets('SWebView accepts custom URL', (WidgetTester tester) async {
      const customUrl = 'https://example.com';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SWebView(url: customUrl),
          ),
        ),
      );

      // Pump and settle to complete all animations
      await tester.pumpAndSettle();

      expect(find.byType(SWebView), findsOneWidget);
    });

    testWidgets('SWebView displays loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SWebView(url: 'https://flutter.dev'),
          ),
        ),
      );

      // Allow the widget to build
      await tester.pump();

      // The loading indicator should be visible
      expect(find.byType(Center), findsWidgets);

      // Pump and settle to complete all animations
      await tester.pumpAndSettle();
    });

    testWidgets('SWebView responds to URL changes',
        (WidgetTester tester) async {
      const initialUrl = 'https://flutter.dev';
      const newUrl = 'https://dart.dev';

      // Create a StatefulWidget to test URL changes
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(url: initialUrl),
        ),
      );

      // Pump and settle initial state
      await tester.pumpAndSettle();

      // Find the button and tap it to change URL
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify the SWebView widget exists with new URL
      final sWebView = tester.widget<SWebView>(find.byType(SWebView));
      expect(sWebView.url, equals(newUrl));

      // Pump and settle to complete animations
      await tester.pumpAndSettle();
    });

    testWidgets('SWebView can have a custom key', (WidgetTester tester) async {
      const testKey = Key('test-webview');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SWebView(
              key: testKey,
              url: 'https://flutter.dev',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(testKey), findsOneWidget);
    });

    test('SWebView widget can be constructed', () {
      expect(() => const SWebView(), returnsNormally);
    });

    test('SWebView accepts custom URL in constructor', () {
      const customUrl = 'https://example.com';
      expect(() => const SWebView(url: customUrl), returnsNormally);
    });

    test('SWebView uses default URL when none provided', () {
      const widget = SWebView();
      expect(widget.url, equals('https://flutter.dev'));
    });

    test('SWebView stores custom URL correctly', () {
      const customUrl = 'https://example.com';
      const widget = SWebView(url: customUrl);
      expect(widget.url, equals(customUrl));
    });

    test('SWebView accepts and stores key', () {
      const testKey = Key('my-webview');
      const widget = SWebView(key: testKey, url: 'https://example.com');
      expect(widget.key, equals(testKey));
    });

    test('SWebView with different URLs are not equal', () {
      const widget1 = SWebView(url: 'https://flutter.dev');
      const widget2 = SWebView(url: 'https://dart.dev');
      expect(widget1.url == widget2.url, isFalse);
    });
  });
}

// Helper widget for testing URL changes
class _TestWidget extends StatefulWidget {
  final String url;

  const _TestWidget({required this.url});

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> {
  late String currentUrl;

  @override
  void initState() {
    super.initState();
    currentUrl = widget.url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentUrl = 'https://dart.dev';
              });
            },
            child: const Text('Change URL'),
          ),
          Expanded(
            child: SWebView(url: currentUrl),
          ),
        ],
      ),
    );
  }
}
