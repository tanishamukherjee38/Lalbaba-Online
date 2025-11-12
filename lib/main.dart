
import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemNavigator, SystemChrome, SystemUiOverlayStyle;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kStartUrl = 'https://www.lalbabaonline.com/';
const Color appRed = Color(0xFFf70707);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LalbabaApp());
}

class LalbabaApp extends StatelessWidget {
  const LalbabaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LALBABA ONLINE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

// ===================== Splash Screen =====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LalbabaHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: 
          CircleAvatar(backgroundImage: AssetImage("lib/assets/logo-icon.png"),radius: 75,) ,
        // child: const Text(
        //   'Lalbaba',
        //   style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        // ),
      ),
    );
  }
}

// ===================== Home (WebView) =====================
class LalbabaHome extends StatefulWidget {
  const LalbabaHome({super.key});

  @override
  State<LalbabaHome> createState() => _LalbabaHomeState();
}

class _LalbabaHomeState extends State<LalbabaHome> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // For Flutter Web
    if (kIsWeb) {
      _launchInSameTab(Uri.parse(kStartUrl));
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final uri = Uri.parse(req.url);
            final isLalbaba = uri.host.contains('lalbabaonline.com');
            if (!isLalbaba) {
              _launchExternally(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(kStartUrl));
  }

  Future<void> _launchExternally(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  void _launchInSameTab(Uri uri) {
    launchUrl(uri, webOnlyWindowName: '_self');
  }

  Future<void> _exitApp() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      // Apple discourages programmatic exit
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ make status bar + nav bar same red as app

    if (kIsWeb) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: appRed,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          if (await _controller.canGoBack()) {
            await _controller.goBack();
          } else {
            if (!mounted) return;
            final shouldExit = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    shape: BeveledRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(2)),
                    // title: const Text('Exit app?'),
                    contentTextStyle:
                        TextStyle(fontSize: 17, color: Colors.black),
                    content: const Text('Do you want to exit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (shouldExit) {
              await _exitApp();
            }
          }
        },
        child: Scaffold(
          // backgroundColor: appRed, // same red as status bar
          appBar: AppBar(
            backgroundColor: appRed,
            elevation: 0,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 0, // invisible appbar to keep status bar red
          ),
          body: RefreshIndicator(
            onRefresh: () => _controller.reload(),
            child: WebViewWidget(controller: _controller),
          ),
        ),
      ),
    );
  }
}
