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
import '../environments/environment.dart';
import 'package:bitcoin_flutter/src/payments/p2pkh.dart';
import 'package:bitcoin_flutter/src/models/networks.dart';

final String btcBaseUrl = environment["endpoints"]["btc"];

Future getBtcTransactionStatus(String txid) async {
  var response;
  var url = btcBaseUrl + 'gettransactionjson/' + txid;
  var client = new http.Client();
  try {
    response = await client.get(url);
  } catch (e) {}

  return response;
}

Future getBtcBalanceByAddress(String address) async {
  var url = btcBaseUrl + 'getbalance/' + address;
  var btcBalance = 0.0;
  try {
    var response = await http.get(url);
    btcBalance = double.parse(response.body) / 1e8;
  } catch (e) {}
  return {'balance': btcBalance, 'lockbalance': 0.0};
}

getBtcNode(root, {index = 0}) {
  var node = root.derivePath("m/44'/" +
      environment["CoinType"]["BTC"].toString() +
      "'/0'/0/" +
      index.toString());
  return node;
}

String getBtcAddressForNode(node) {
  return P2PKH(
          data: new P2PKHData(pubkey: node.publicKey),
          network: environment["chains"]["BTC"]["network"])
      .data
      .address;
}
