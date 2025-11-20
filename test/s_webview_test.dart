import 'package:flutter/material.dart';
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
  });
}
