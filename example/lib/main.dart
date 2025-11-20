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
  String currentUrl = 'https://flutter.dev';

  final List<Map<String, String>> websites = [
    {'name': 'Flutter', 'url': 'https://flutter.dev'},
    {'name': 'Dart', 'url': 'https://dart.dev'},
    {'name': 'GitHub', 'url': 'https://github.com'},
    {'name': 'Stack Overflow', 'url': 'https://stackoverflow.com'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SWebView Example'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'Select Website',
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Currently viewing: $currentUrl',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SWebView(
              key: ValueKey(currentUrl),
              url: currentUrl,
            ),
          ),
        ],
      ),
    );
  }
}
