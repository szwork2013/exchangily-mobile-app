import 'dart:convert';
import 'package:exchangilymobileapp/services/db_service.dart';
import 'package:exchangilymobileapp/services/shared_service.dart';
import 'package:flutter/material.dart';
import 'package:exchangilymobileapp/enums/screen_state.dart';
import 'package:exchangilymobileapp/logger.dart';
import 'package:exchangilymobileapp/models/wallet.dart';
import 'package:exchangilymobileapp/service_locator.dart';
import 'package:exchangilymobileapp/services/wallet_service.dart';
import 'package:exchangilymobileapp/screen_state/base_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardScreenState extends BaseState {
  final log = getLogger('DahsboardScreenState');
  List<WalletInfo> walletInfo;
  WalletService walletService = locator<WalletService>();
  SharedService sharedService = locator<SharedService>();
  DataBaseService databaseService = locator<DataBaseService>();
  final double elevation = 5;
  double totalUsdBalance = 0;
  double coinUsdBalance;
  double gasAmount = 0;
  String exgAddress = '';
  List<double> assetsInExchange = [];
  final storage = new FlutterSecureStorage();
  String wallets;
  List walletInfoCopy = [];
  BuildContext context;

  final wallet = WalletInfo(
      name: 'bitcoin',
      tickerName: 'BTC',
      tokenType: '',
      address: 'fasdgasghasfdhgafhafh',
      availableBalance: 45767,
      lockedBalance: 236526.034,
      assetsInExchange: 12234);

  initDb() {
    var test = databaseService.initDb();
    test.then((res) {
      log.w(res);
    });
  }

  deleteDb() async {
    var res = await databaseService.deleteDb();
    log.e(res);
  }

  deleteWallet() async {
    await databaseService.deleteWallet(1);
  }

  closeDB() async {
    await databaseService.closeDb();
  }

  create() async {
    var res = await databaseService.insert(wallet);
    log.w(res);
  }

  udpate() async {
    //  await databaseService.update(test);
  }

  getAll() {
    databaseService.getAll();
  }

  calcTotalBal(numberOfCoins) {
    totalUsdBalance = 0;
    for (var i = 0; i < numberOfCoins; i++) {
      log.e(walletInfo[i].usdValue);
      totalUsdBalance = totalUsdBalance + walletInfo[i].usdValue;
      log.i('Total ${totalUsdBalance.toStringAsFixed(2)}');
    }
    setState(ViewState.Idle);
  }

  getGas() async {
    setState(ViewState.Busy);
    for (var i = 0; i < walletInfo.length; i++) {
      String tName = walletInfo[i].tickerName;
      if (tName == 'EXG') {
        exgAddress = walletInfo[i].address;
        gasAmount = await walletService.gasBalance(exgAddress);
        log.w(gasAmount);
        setState(ViewState.Idle);
        return gasAmount;
      }
    }
    setState(ViewState.Idle);
  }

  // Retrive Wallets Object From Storage

  retrieveWallets() async {
    setState(ViewState.Busy);
    await databaseService.getAll().then((res) {
      walletInfo = res;
      log.w('wallet info $walletInfo');
      setState(ViewState.Idle);
    })

        // await storage.read(key: 'wallets').then((encodedJsonWallets) async {
        //   if (encodedJsonWallets == null) {
        //     log.e('Local storage null');
        //     Navigator.pushNamed(context, '/walletSetup');
        //   }
        //   final decodedWallets = jsonDecode(encodedJsonWallets);
        //   log.w(decodedWallets);
        //   WalletInfoList walletInfoList = WalletInfoList.fromJson(decodedWallets);
        //   log.e(walletInfoList.wallets[0].usdValue);

        //   walletInfo = walletInfoList.wallets;
        //   walletInfoCopy = walletInfo.map((element) => element).toList();
        //   log.i(walletInfo.length);
        //   calcTotalBal(walletInfo.length);
        //   setState(ViewState.Idle);
        // })
        .catchError((error) {
      log.e('Catch Error $error');
      setState(ViewState.Idle);
    });
  }

  /* Get Exchange Assets */

  getExchangeAssets() async {
    setState(ViewState.Busy);
    assetsInExchange.clear();
    var res = await walletService.assetsBalance(exgAddress);
    var length = res.length;
    for (var i = 0; i < length; i++) {
      String coin = res[i]['coin'];
      for (var j = 0; j < length; j++) {
        if (coin == walletInfo[j].tickerName)
          walletInfo[j].assetsInExchange = res[i]['amount'];
      }
    }
    walletInfoCopy = walletInfo.map((element) => element).toList();
    setState(ViewState.Idle);
  }

  Future refreshBalance() async {
    setState(ViewState.Busy);
    // totalUsdBalance = 0;
    // Make a copy of walletInfo as after refresh its count doubled so this way we seperate the UI walletinfo from state
    walletInfoCopy = walletInfo.map((element) => element).toList();
    int length = walletInfoCopy.length;
    log.w('Wallet copy ${walletInfoCopy.length}');
    List<String> token = walletService.tokenType;
    walletInfo.clear();
    double walletBal = 0;
    double walletLockedBal = 0;
    for (var i = 0; i < length; i++) {
      String tickerName = walletInfoCopy[i].tickerName;
      String address = walletInfoCopy[i].address;
      String name = walletInfoCopy[i].name;
      await walletService
          .coinBalanceByAddress(tickerName, address, token[i])
          .then((balance) async {
        walletBal = balance['balance'];
        walletLockedBal = balance['lockbalance'];
        double marketPrice = await walletService.getCoinMarketPrice(name);
        coinUsdBalance =
            walletService.calculateCoinUsdBalance(marketPrice, walletBal);
        WalletInfo wi = WalletInfo(
            tickerName: tickerName,
            tokenType: token[i],
            address: address,
            availableBalance: walletBal,
            lockedBalance: walletLockedBal,
            usdValue: coinUsdBalance,
            name: name);
        walletInfo.add(wi);
        await databaseService.insert(wi);
      }).catchError((error) {
        log.e('Something went wrong  - $error');
      });
    }
    calcTotalBal(length);
    await getGas();
    await getExchangeAssets();
    wallets = jsonEncode(walletInfo);
    await storage.delete(key: 'wallets');
    await storage.write(key: 'wallets', value: wallets);
    setState(ViewState.Idle);
    return walletInfo;
  }

  onBackButtonPressed() async {
    sharedService.context = context;
    await sharedService.closeApp();
  }
}
