import 'package:flutter_test/flutter_test.dart';
import 'package:s_webview/s_webview.dart';

void main() {
  test('SWebView can be instantiated with default URL', () {
    expect(() => SWebView(), returnsNormally);
  });

  test('SWebView accepts custom URL', () {
    const customUrl = 'https://example.com';
    expect(() => SWebView(url: customUrl), returnsNormally);
  });
}
