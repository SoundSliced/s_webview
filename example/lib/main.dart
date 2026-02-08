import 'package:s_webview/s_webview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SWebView Feature Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  String currentUrl = 'https://flutter.dev';
  String searchText = '';
  bool showFeatures = true;
  String? lastError;
  bool activateStackedButtons = false;

  // Sites categorized by iframe compatibility on Flutter Web
  // With auto-detection enabled (default), CORS proxy is applied only when needed
  final List<Map<String, dynamic>> websites = [
    {'name': 'Wikipedia', 'url': 'https://www.wikipedia.org'},
    {'name': 'Google', 'url': 'https://www.google.com'},
    {'name': 'GitHub', 'url': 'https://github.com'},
    {
      'name': 'Stack Overflow',
      'url': 'https://stackoverflow.com',
    },
    {
      'name': 'MDN Web Docs',
      'url': 'https://developer.mozilla.org',
    },
    {'name': 'W3Schools', 'url': 'https://www.w3schools.com'},
    {'name': 'Flutter.dev', 'url': 'https://flutter.dev'},
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        tabController: _tabController,
        actions: [
          SizedBox(
            width: 200,
            height: 20,
            child: Row(
              spacing: 8,
              children: [
                const Text(
                  'Activate stacked Buttons:',
                  style: TextStyle(fontSize: 12),
                ),
                SToggle(
                  value: activateStackedButtons,
                  onChange: (val) {
                    if (mounted) {
                      setState(() {
                        activateStackedButtons = val;
                      });
                    }
                  },
                  onColor: Colors.green,
                  offColor: Colors.red,
                  size: 40,
                ),
              ],
            ),
          ),

          // Dropdown for website selection
          SDropdown(
            items:
                websites.map((website) => website['name'] as String).toList(),
            selectedItem: _getSelectedWebsiteName(),
            onChanged: (String? selectedName) {
              if (selectedName != null && selectedName != 'Select Website') {
                final selectedWebsite = websites
                    .firstWhere((website) => website['name'] == selectedName);
                if (mounted) {
                  setState(() {
                    currentUrl = selectedWebsite['url'] as String;
                  });
                }
              }
            },
            hintText: 'Select Website',
            width: 200,
            overlayHeight: 600,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // WebView Tab
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'URL: $currentUrl',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (lastError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Failed to Load',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700),
                            ),
                            Text(
                              lastError!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.red.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 18, color: Colors.red.shade700),
                        onPressed: () {
                          if (mounted) {
                            setState(() => lastError = null);
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    SWebView(
                      key: ValueKey(currentUrl),
                      url: currentUrl,
                      showToolbar: !activateStackedButtons,
                      onError: (error) {
                        if (mounted) {
                          setState(() {
                            lastError = error;
                          });
                        }
                      },
                      onIframeBlocked: () {
                        if (mounted && kIsWeb) {
                          setState(() {
                            lastError =
                                'This site blocks iframe embedding (X-Frame-Options/CSP). '
                                'Auto-detection failed or site not supported. Click "Open in Browser".';
                          });
                        }
                      },
                    ),

                    // Show "Open in Browser" button on web when error occurs
                    if (kIsWeb && activateStackedButtons)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: SWebView.tapTarget(
                          child: Row(
                            spacing: 12,
                            children: [
                              // Conditional button: Show "Clear from Cache" if URL is in cache, otherwise "Reload with CORS Proxy"
                              if (SWebView.isUrlInProxyCache(currentUrl))
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final urlToLoad = currentUrl;
                                    await SWebView.removeFromCache(urlToLoad);
                                    // Trigger reload by forcing widget rebuild via URL change
                                    if (mounted) {
                                      setState(() {
                                        currentUrl = '';
                                      });
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      if (mounted) {
                                        setState(() {
                                          currentUrl = urlToLoad;
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Clear from Proxy Cache'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    elevation: 8,
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final urlToLoad = currentUrl;
                                    await SWebView.retryWithProxy(urlToLoad);
                                    // Trigger reload by forcing widget rebuild via URL change
                                    if (mounted) {
                                      setState(() {
                                        currentUrl = '';
                                      });
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      if (mounted) {
                                        setState(() {
                                          currentUrl = urlToLoad;
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reload with CORS proxy'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    elevation: 8,
                                  ),
                                ),

                              // Open in Browser button
                              ElevatedButton.icon(
                                onPressed: () =>
                                    SWebView.openInNewTab(currentUrl),
                                icon: const Icon(Icons.open_in_browser),
                                label: const Text('Open in Browser'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  elevation: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Info Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureSection(
                  '🔧 Why Some Websites Fail to Load',
                  'Understanding connection issues',
                  [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            kIsWeb ? Colors.red.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: kIsWeb ? Colors.red : Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (kIsWeb) ...[
                            const Row(
                              children: [
                                Icon(Icons.web, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Flutter Web Platform - iframe Restrictions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'On Flutter Web, WebView uses an <iframe> under the hood. '
                              'Many websites block iframe embedding using:\n\n'
                              '🚫 X-Frame-Options: SAMEORIGIN - Prevents embedding in iframes\n'
                              '🚫 Content-Security-Policy: frame-ancestors - Restricts where the page can be embedded\n'
                              '🚫 Strict cookies/authentication - Don\'t work inside iframes\n\n'
                              'This is a browser security feature, not a bug in the WebView.\n\n'
                              '✅ Solution #1: Enable CORS proxy (default) to strip blocking headers\n'
                              '✅ Solution #2: Use the "Open in Browser" button to view blocked sites externally.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sites marked with ⚠️ in the menu will likely fail on web.',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Common Causes on Native Platforms:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Custom HTTP Headers: Some websites block requests with non-standard headers. '
                              'By default, custom headers are NOT applied to avoid blocking.\n\n'
                              '• User-Agent Restrictions: Some sites require specific user-agent strings.\n\n'
                              '• SSL/Certificate Issues: Websites with certificate redirects may timeout.\n\n'
                              '• CORS Policies: Cross-origin requests may be restricted.\n\n'
                              '• Network Requirements: Some networks require proxy configuration.\n\n'
                              'On native platforms (iOS, Android, Desktop), most sites work without issues.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (kIsWeb) ...[
                  _buildFeatureSection(
                    '🔌 Auto-Detection Settings',
                    'Automatic CORS proxy for iframe restrictions',
                    [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.vpn_key,
                                    color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Frame Restriction Detection',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enabled: SWebView automatically checks if a website has X-Frame-Options or CSP restrictions. '
                              'If restrictions are detected, CORS proxy is applied automatically.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✓ Automatic: No manual configuration needed\n'
                                '✓ Fast: Uses HTTP HEAD requests (5s timeout)\n'
                                '✓ Smart: Only applies proxy when needed',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 20),
                SWebView.tapTarget(
                  child: _buildFeatureSection(
                    kIsWeb
                        ? '🌐 Website Compatibility (Web)'
                        : '✅ Working Sites (Native)',
                    kIsWeb
                        ? 'Auto-detection enabled - most sites should work'
                        : 'All sites work on native platforms',
                    [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (kIsWeb) ...[
                              const Text(
                                'With auto-detection: Most sites work by automatically detecting and bypassing frame restrictions',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...websites.map((site) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${site['name']}: ${site['url']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ] else ...[
                              const Text(
                                'On native platforms (iOS, Android, Windows, macOS, Linux), '
                                'there are NO iframe restrictions. All sites work:',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              ...websites.map((site) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${site['name']}: ${site['url']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(
    String title,
    String description,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _getSelectedWebsiteName() {
    try {
      return websites.firstWhere(
          (website) => website['url'] == currentUrl)['name'] as String;
    } catch (_) {
      return 'Select Website';
    }
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final List<Widget> actions;

  const CustomAppBar({
    super.key,
    required this.tabController,
    required this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120); // Change from 78 to 120

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        spacing: 5,
        children: [
          Row(
            children: actions,
          ),
          Flexible(
            child: SizedBox(
              height: 48,
              child: TabBar(
                controller: tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.web), text: 'WebView'),
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
