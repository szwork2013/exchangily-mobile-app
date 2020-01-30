import 'package:exchangilymobileapp/environments/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

// realtime: https://jsfiddle.net/TradingView/yozeu6k1/

class LoadHTMLFileToWEbView extends StatefulWidget {
  String pair;
  LoadHTMLFileToWEbView(this.pair);
  @override
  _LoadHTMLFileToWEbViewState createState() => _LoadHTMLFileToWEbViewState();
}

class _LoadHTMLFileToWEbViewState extends State<LoadHTMLFileToWEbView> {
  WebViewController _controller;
  @override
  Widget build(BuildContext context) {
    return
      Container(
        padding: EdgeInsets.all(0),
        margin: EdgeInsets.all(0),
        height: 460,
        child:
        WebView(
          initialUrl: '',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller = webViewController;
            _loadHtmlFromAssets();
          },
        )
      );
  }


  _loadHtmlFromAssets() async {
    //var pair = widget.pair.replaceAll(RegExp('/'), '');
    // pair = 'index';
    var pairArray = widget.pair.split('/');
    String fileText = await rootBundle.loadString('assets/pages/index.html');
    fileText = fileText.replaceAll('BTC', pairArray[0]).replaceAll('USDT', pairArray[1])
        .replaceAll('https://kanbantest.fabcoinapi.com/', environment['endpoints']['kanban'])
        .replaceAll('wss://kanbantest.fabcoinapi.com/ws/', environment['websocket']);

    _controller.loadUrl( Uri.dataFromString(
        fileText,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8')
    ).toString());
  }

}
