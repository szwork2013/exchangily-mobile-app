/*
* Copyright (c) 2020 Exchangily LLC
*
* Licensed under Apache License v2.0
* You may obtain a copy of the License at
*
*      https://www.apache.org/licenses/LICENSE-2.0
*
*----------------------------------------------------------------------
* Author: ken.qiu@exchangily.com
*----------------------------------------------------------------------
*/

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'package:exchangilymobileapp/environments/environment.dart';
import 'package:exchangilymobileapp/service_locator.dart';
import 'package:exchangilymobileapp/services/api_service.dart';

class TradeService {
  Api _api = locator<Api>();
  Future<int> getAllPrices() async {
    final response =
        await http.get('https://jsonplaceholder.typicode.com/posts/1');
    return 1;
  }

  getAllPriceChannel() {
    return IOWebSocketChannel.connect(environment['websocket'] + 'allprices');
  }

  getOrderListChannel(String pair) {
    var wsString = environment['websocket'] + 'orders' + '@' + pair;
    return IOWebSocketChannel.connect(wsString);
  }

  getTradeListChannel(String pair) {
    var wsString = environment['websocket'] + 'trades' + '@' + pair;
    return IOWebSocketChannel.connect(wsString);
  }

  getTickerChannel(String pair, String interval) {
    var wsString =
        environment['websocket'] + 'ticker' + '@' + pair + '@' + interval;
    return IOWebSocketChannel.connect(wsString);
  }

  getCoinMarketPrice(String name) async {
    double currentUsdValue;
    var usdVal = await _api.getCoinsUsdValue();
    if (name == 'exchangily') {
      return currentUsdValue = 0.2;
    }

    if (name == 'btc') {
      name = 'bitcoin';
    } else if (name == 'fab') {
      name = 'fabcoin';
    } else if (name == 'eth') {
      name = 'ethereum';
    }
    currentUsdValue = usdVal[name]['usd'];
    return currentUsdValue;
  }

  getAssetsBalance(String exgAddress) async {
    return await _api.getAssetsBalance(exgAddress);
  }

  getOrders(String exgAddress) async {
    return await _api.getOrders(exgAddress);
  }
}
