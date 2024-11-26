import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:html' deferred as html; // Only used on the web
import 'dart:ui' deferred as ui; // Only used on the web

class ThreeDSPage extends StatefulWidget {
  final String? html;
  final String? returnURL;

  const ThreeDSPage(this.html, this.returnURL, {Key? key}) : super(key: key);

  @override
  _ThreeDSPageState createState() => _ThreeDSPageState();
}

class _ThreeDSPageState extends State<ThreeDSPage> {
  late final WebViewController _controller;

  @override
  void initState() async {
    super.initState();

    if (kIsWeb) {
      // Register the view factory for web only
      await html.loadLibrary();
      await ui.loadLibrary();
      //ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'iframe-html-viewer',
        (int viewId) {
          final iframe = html.IFrameElement()
            ..srcdoc = widget.html ?? ""
            ..style.border = 'none';
          return iframe;
        },
      );
    } else {
      // Initialize WebViewController for mobile platforms only
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..addJavaScriptChannel('Toaster', onMessageReceived: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        })
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {},
            onPageStarted: (String url) {
              if (url.startsWith(widget.returnURL ?? "")) {
                Navigator.of(context).pop();
              }
            },
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {
              if (Platform.isIOS) {
                Navigator.of(context).pop();
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(widget.returnURL ?? "")) {
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(widget.html.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("3DS")),
      body: kIsWeb
          ? HtmlElementView(viewType: 'iframe-html-viewer') // For web
          : WebViewWidget(controller: _controller), // For mobile
    );
  }
}
