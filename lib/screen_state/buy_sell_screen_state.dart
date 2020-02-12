/*
* Copyright (c) 2020 Exchangily LLC
*
* Licensed under Apache License v2.0
* You may obtain a copy of the License at
*
*      https://www.apache.org/licenses/LICENSE-2.0
*
*----------------------------------------------------------------------
* Author: barry-ruprai@exchangily.com
*----------------------------------------------------------------------
*/

import 'dart:async';
import 'dart:typed_data';

import 'package:exchangilymobileapp/enums/screen_state.dart';
import 'package:exchangilymobileapp/environments/coins.dart';
import 'package:exchangilymobileapp/environments/environment.dart';
import 'package:exchangilymobileapp/localizations.dart';
import 'package:exchangilymobileapp/logger.dart';
import 'package:exchangilymobileapp/models/order-model.dart';
import 'package:exchangilymobileapp/models/orders.dart';
import 'package:exchangilymobileapp/models/trade-model.dart';
import 'package:exchangilymobileapp/models/wallet.dart';
import 'package:exchangilymobileapp/screen_state/base_state.dart';
import 'package:exchangilymobileapp/screens/place_order/widgets/my_orders.dart';
import 'package:exchangilymobileapp/service_locator.dart';
import 'package:exchangilymobileapp/services/db/wallet_database_service.dart';
import 'package:exchangilymobileapp/services/dialog_service.dart';
import 'package:exchangilymobileapp/services/shared_service.dart';
import 'package:exchangilymobileapp/services/trade_service.dart';
import 'package:exchangilymobileapp/services/wallet_service.dart';
import 'package:exchangilymobileapp/utils/abi_util.dart';
import 'package:exchangilymobileapp/utils/decoder.dart';
import 'package:exchangilymobileapp/utils/kanban.util.dart';
import 'package:exchangilymobileapp/utils/keypair_util.dart';
import 'package:exchangilymobileapp/utils/string_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:keccak/keccak.dart';
import 'package:random_string/random_string.dart';
import 'package:web_socket_channel/io.dart';

import 'package:exchangilymobileapp/shared/globals.dart' as globals;
import 'package:convert/convert.dart';
import 'package:hex/hex.dart';

class BuySellScreenState extends BaseState {
  final log = getLogger(' BuySellScreenState');
  List<WalletInfo> walletInfo;
  WalletService walletService = locator<WalletService>();
  SharedService sharedService = locator<SharedService>();
  TradeService tradeService = locator<TradeService>();
  WalletDataBaseService databaseService = locator<WalletDataBaseService>();
  BuildContext context;
  bool bidOrAsk;
  String baseCoinName;
  String targetCoinName;

  List<OrderModel> sell;
  List<OrderModel> buy;
  DialogService _dialogService = locator<DialogService>();
  double currentPrice = 0;
  double currentQuantity = 0;
  double sliderValue = 10.0;
  IOWebSocketChannel orderListChannel;
  IOWebSocketChannel tradeListChannel;
  double price;
  double quantity;
  String exgAddress;
  var coin;
  final GlobalKey<MyOrdersState> myordersState = new GlobalKey<MyOrdersState>();
  Orders orders;

  orderListFromTradeService() {
    setState(ViewState.Busy);
    orderListChannel =
        tradeService.getOrderListChannel(targetCoinName + baseCoinName);
    setState(ViewState.Idle);
  }

  tradeListFromTradeService() {
    setState(ViewState.Busy);
    tradeListChannel =
        tradeService.getTradeListChannel(targetCoinName + baseCoinName);
    setState(ViewState.Idle);
  }

  // Close the Web Socket Connection

  closeChannles() {
    orderListChannel.sink.close();
    tradeListChannel.sink.close();
    log.e('close channels');
  }

  // Order List
  Future orderList() async {
    setState(ViewState.Busy);
    orderListChannel.stream.listen((ordersString) {
      orders = Decoder.fromOrdersJsonArray(ordersString);
      log.w('3.1');
      showOrders(orders);
      log.w('3.2');
    });
    setState(ViewState.Idle);
  }

  // Trade List
  tradeList() async {
    setState(ViewState.Busy);
    tradeListChannel.stream.listen((tradesString) {
      List<TradeModel> trades = Decoder.fromTradesJsonArray(tradesString);
      log.i('trades= $trades');
      log.w('5.1');
      if (trades != null && trades.length > 0) {
        TradeModel latestTrade = trades[0];
        log.w('5.2');
        //if (this.mounted) {
        //   setState(() => {
        currentPrice = latestTrade.price;
        //   });
        //  }
      }
    });
    setState(ViewState.Idle);
  }

  // Retrieve Wallets

  retrieveWallets() async {
    setState(ViewState.Busy);
    await databaseService.getAll().then((walletList) {
      walletInfo = walletList;

      for (var i = 0; i < walletInfo.length; i++) {
        coin = walletInfo[i];
        if (coin.tickerName == 'EXG') {
          exgAddress = coin.address;
          // _myordersState.currentState.refresh(exgAddress);
          this.refresh(exgAddress);
          break;
        }
      }
      setState(ViewState.Idle);
    }).catchError((error) {
      setState(ViewState.Idle);
    });
  }

  refresh(String address) {
    setState(ViewState.Busy);
    if (address == null) {
      return;
    }
    Timer.periodic(Duration(seconds: 3), (Timer time) async {
      // print("Yeah, this line is printed after 3 seconds");
      var balances = await tradeService.getAssetsBalance(address);
      var orders = await tradeService.getOrders(address);

      List<Map<String, dynamic>> newbals = [];
      List<Map<String, dynamic>> openOrds = [];
      List<Map<String, dynamic>> closeOrds = [];

      for (var i = 0; i < balances.length; i++) {
        var bal = balances[i];
        var coinType = int.parse(bal['coinType']);
        var unlockedAmount = bigNum2Double(bal['unlockedAmount']);
        var lockedAmount = bigNum2Double(bal['lockedAmount']);
        var newbal = {
          "coin": coin_list[coinType]['name'],
          "amount": unlockedAmount,
          "lockedAmount": lockedAmount
        };
        newbals.add(newbal);
      }

      for (var i = 0; i < orders.length; i++) {
        var order = orders[i];
        var orderHash = order['orderHash'];
        var address = order['address'];
        var orderType = order['orderType'];
        var bidOrAsk = order['bidOrAsk'];
        var pairLeft = order['pairLeft'];
        var pairRight = order['pairRight'];
        var price = bigNum2Double(order['price']);
        var orderQuantity = bigNum2Double(order['orderQuantity']);
        var filledQuantity = bigNum2Double(order['filledQuantity']);
        var time = order['time'];
        var isActive = order['isActive'];

        //{ "block":  "absdda...", "type": "Buy", "pair": "EXG/USDT", "price": 1, "amount": 1000.00},
        var newOrd = {
          'orderHash': orderHash,
          'type': (bidOrAsk == true) ? 'Buy' : 'Sell',
          'pair': coin_list[pairLeft]['name'].toString() +
              '/' +
              coin_list[pairRight]['name'].toString(),
          'price': price,
          'amount': orderQuantity,
          'filledAmount': filledQuantity
        };

        if (isActive == true) {
          openOrds.add(newOrd);
        } else {
          closeOrds.add(newOrd);
        }
      }

      var newOpenOrds =
          openOrds.length > 10 ? openOrds.sublist(0, 10) : openOrds;
      var newCloseOrds =
          closeOrds.length > 10 ? closeOrds.sublist(0, 10) : closeOrds;
      if ((myordersState != null) && (myordersState.currentState != null)) {
        myordersState.currentState
            .refreshBalOrds(newbals, newOpenOrds, newCloseOrds);
      }
    });
    setState(ViewState.Idle);
  }
  // Generate Order Hash

  generateOrderHash(bidOrAsk, orderType, baseCoin, targetCoin, amount, price,
      timeBeforeExpiration) {
    setState(ViewState.Busy);
    var randomStr = randomString(32);
    var concatString = [
      bidOrAsk,
      orderType,
      baseCoin,
      targetCoin,
      amount,
      price,
      timeBeforeExpiration,
      randomStr
    ].join('');
    var outputHashData = keccak(stringToUint8List(concatString));

    // if needed convert the output byte array into hex string.
    var output = hex.encode(outputHashData);
    setState(ViewState.Idle);
    return output;
  }

// Tx Hex For Place Order
  txHexforPlaceOrder(seed) async {
    setState(ViewState.Busy);
    var timeBeforeExpiration = 423434342432;
    var orderType = 1;
    var baseCoin = walletService.getCoinTypeIdByName(baseCoinName);
    var targetCoin = walletService.getCoinTypeIdByName(targetCoinName);
    var orderHash = this.generateOrderHash(bidOrAsk, orderType, baseCoin,
        targetCoin, quantity, price, timeBeforeExpiration);

    var qtyBigInt = BigInt.from(quantity * 1e18);
    var priceBigInt = BigInt.from(price * 1e18);

    var abiHex = getCreateOrderFuncABI(
        bidOrAsk,
        orderType,
        baseCoin,
        targetCoin,
        qtyBigInt,
        priceBigInt,
        timeBeforeExpiration,
        false,
        orderHash);
    var nonce = await getNonce(exgAddress);

    var keyPairKanban = getExgKeyPair(seed);
    var exchangilyAddress = await getExchangilyAddress();
    var txKanbanHex = await signAbiHexWithPrivateKey(
        abiHex,
        HEX.encode(keyPairKanban["privateKey"]),
        exchangilyAddress,
        nonce,
        environment["chains"]["KANBAN"]["gasPrice"],
        environment["chains"]["KANBAN"]["gasLimit"]);
    setState(ViewState.Idle);
    return txKanbanHex;
  }

  // Show Orders

  showOrders(Orders orders) async {
    setState(ViewState.Busy);
    var newbuy = orders.buy;
    var newsell = orders.sell;
    var preItem;
    for (var i = 0; i < newbuy.length; i++) {
      var item = newbuy[i];
      var price = item.price;
      var orderQuantity = item.orderQuantity;

      var filledQuantity = item.filledQuantity;
      if (preItem != null) {
        if (preItem.price == price) {
          preItem.orderQuantity =
              doubleAdd(preItem.orderQuantity, orderQuantity);
          preItem.filledQuantity =
              doubleAdd(preItem.filledQuantity, filledQuantity);
          newbuy.removeAt(i);
          i--;
        } else {
          preItem = item;
        }
      } else {
        preItem = item;
      }
    }

    preItem = null;
    for (var i = 0; i < newsell.length; i++) {
      var item = newsell[i];
      var price = item.price;
      var orderQuantity = item.orderQuantity;
      var filledQuantity = item.filledQuantity;
      if (preItem != null) {
        if (preItem.price == price) {
          preItem.orderQuantity =
              doubleAdd(preItem.orderQuantity, orderQuantity);
          preItem.filledQuantity =
              doubleAdd(preItem.filledQuantity, filledQuantity);
          newsell.removeAt(i);
          i--;
        } else {
          preItem = item;
        }
      } else {
        preItem = item;
      }
    }

    if (!listEquals(newbuy, this.buy) || !listEquals(newsell, this.sell)) {
      // if (this.mounted) {
      //setState(() => {
      this.sell = (newsell.length > 5)
          ? (newsell.sublist(newsell.length - 5))
          : newsell;
      this.buy = (newbuy.length > 5) ? (newbuy.sublist(0, 5)) : newbuy;
      //   });
      // }
    }
    setState(ViewState.Idle);
  }

  // Place Orders

  placeOrder() {
    setState(ViewState.Busy);
    checkPass(context);
    setState(ViewState.Idle);
  }

  // Check Pass
  checkPass(context) async {
    setState(ViewState.Busy);
    var res = await _dialogService.showDialog(
        title: AppLocalizations.of(context).enterPassword,
        description:
            AppLocalizations.of(context).dialogManagerTypeSamePasswordNote,
        buttonTitle: AppLocalizations.of(context).confirm);
    if (res.confirmed) {
      String mnemonic = res.returnedText;
      Uint8List seed = walletService.generateSeed(mnemonic);

      var txHex = await txHexforPlaceOrder(seed);
      var resKanban = await sendKanbanRawTransaction(txHex);
    } else {
      if (res.returnedText != 'Closed') {
        showNotification(context);
      }
    }
    setState(ViewState.Idle);
  }

// Handle Text Change
  void handleTextChanged(String name, String text) {
    setState(ViewState.Busy);
    if (name == 'price') {
      try {
        this.price = double.parse(text);
      } catch (e) {}
    }
    if (name == 'quantity') {
      try {
        this.quantity = double.parse(text);
      } catch (e) {}
    }
    setState(ViewState.Idle);
  }

// Show Notification
  showNotification(context) {
    walletService.showInfoFlushbar(
        AppLocalizations.of(context).passwordMismatch,
        AppLocalizations.of(context).pleaseProvideTheCorrectPassword,
        Icons.cancel,
        globals.red,
        context);
  }
}
