import 'dart:typed_data';

import 'package:exchangilymobileapp/logger.dart';
import 'package:exchangilymobileapp/service_locator.dart';
import 'package:exchangilymobileapp/services/dialog_service.dart';
import 'package:exchangilymobileapp/services/wallet_service.dart';
import 'package:exchangilymobileapp/screen_state/base_state.dart';
import 'package:flutter/material.dart';
import '../shared/globals.dart' as globals;

class SendScreenState extends BaseState {
  final log = getLogger('SendState');
  DialogService _dialogService = locator<DialogService>();
  WalletService walletService = locator<WalletService>();
  var options = {};

  Future checkPass(tickerName, toWalletAddress, amount, context) async {
    log.w('dialog called');
    var res = await _dialogService.showDialog(
        title: 'Enter Password',
        description:
            'Type the same password which you entered while creating the wallet');
    if (res.confirmed) {
      log.w('Pass matched');
      log.w('${res.fieldOne}');
      String mnemonic = res.fieldOne;
      Uint8List seed = walletService.generateSeed(mnemonic);
      log.w(seed);
      var ret = await walletService.sendTransaction(
          tickerName, seed, [0], toWalletAddress, amount, options, true);
      //  Navigator.pushNamed(context, '/walletFeatures');
      log.w(ret["errMsg"]);
      log.w(ret["txHash"]);
    } else {
      if (res.fieldOne != 'Closed') {
        log.w('Wrong password');
        showNotification(context);
      }
    }
    log.w('dialog closed');
  }

  showNotification(context) {
    walletService.showInfoFlushbar('Password Mismatch',
        'Please enter the correct pasword', Icons.cancel, globals.red, context);
  }
}