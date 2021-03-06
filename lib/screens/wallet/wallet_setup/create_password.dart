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

import 'package:exchangilymobileapp/enums/screen_state.dart';
import 'package:exchangilymobileapp/localizations.dart';
import 'package:exchangilymobileapp/logger.dart';
import 'package:exchangilymobileapp/screens/base_screen.dart';
import 'package:exchangilymobileapp/services/wallet_service.dart';
import 'package:exchangilymobileapp/screen_state/wallet/wallet_setup/create_password_screen_state.dart';
import 'package:shimmer/shimmer.dart';
import '../../../shared/globals.dart' as globals;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:exchangilymobileapp/shared/ui_helpers.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String randomMnemonicFromRoute;
  const CreatePasswordScreen({Key key, this.randomMnemonicFromRoute})
      : super(key: key);

  @override
  _CreatePasswordScreenState createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final log = getLogger('CreatePassword');
  FocusNode passFocus = FocusNode();
  TextEditingController _passTextController = TextEditingController();
  TextEditingController _confirmPassTextController = TextEditingController();
  WalletService walletService = WalletService();

  @override
  Widget build(BuildContext context) {
    return BaseScreen<CreatePasswordScreenState>(
      onModelReady: (model) {
        model.randomMnemonicFromRoute = widget.randomMnemonicFromRoute;
        model.context = context;
        model.errorMessage = '';
        model.passwordMatch = false;
      },
      builder: (context, model, child) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(AppLocalizations.of(context).secureYourWallet),
          backgroundColor: globals.secondaryColor,
        ),
        body: Container(
            padding: EdgeInsets.all(15),
            child: ListView(
              scrollDirection: Axis.vertical,
              children: <Widget>[
                UIHelper.verticalSpaceSmall,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context).setPasswordConditions,
                      style: Theme.of(context).textTheme.bodyText1,
                      textAlign: TextAlign.left,
                    ),
                    UIHelper.verticalSpaceSmall,
                    _buildPasswordTextField(model),
                    UIHelper.verticalSpaceSmall,
                    _buildConfirmPasswordTextField(model),
                    model.password != ''
                        ? model.passwordMatch && model.password.isNotEmpty
                            ? Center(
                                child: Text(
                                AppLocalizations.of(context).passwordMatched,
                                style: TextStyle(color: globals.white),
                              ))
                            : Center(
                                child: Text(
                                    AppLocalizations.of(context)
                                        .passwordDoesNotMatched,
                                    style: TextStyle(color: globals.grey)))
                        : Text(''),
                    UIHelper.verticalSpaceSmall,
                    Center(
                        child: Text(model.errorMessage,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                .copyWith(color: globals.red))),
                    UIHelper.verticalSpaceLarge,
                    UIHelper.verticalSpaceLarge,
                    Center(
                      child: model.state == ViewState.Busy
                          ? Shimmer.fromColors(
                              baseColor: globals.primaryColor,
                              highlightColor: globals.grey,
                              child: Text(
                                AppLocalizations.of(context).creatingWallet,
                                style: Theme.of(context).textTheme.button,
                              ),
                            )
                          : _buildCreateNewWalletButton(model, context),
                    ),
                    UIHelper.verticalSpaceLarge,
                    Text(
                      AppLocalizations.of(context).setPasswordNote,
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .textTheme
                          .headline
                          .copyWith(fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ],
            )),
      ),
    );
  }

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------

                                    Widget Password

--------------------------------------------------------------------------------------------------------------------------------------------------------------*/

  Widget _buildPasswordTextField(model) {
    return TextField(
        onChanged: (String pass) {
          setState(() {
            model.checkPassword(pass);
          });
        },
        focusNode: passFocus,
        autofocus: true,
        controller: _passTextController,
        obscureText: true,
        maxLength: 16,
        style: model.checkPasswordConditions
            ? TextStyle(color: globals.primaryColor, fontSize: 16)
            : TextStyle(color: globals.grey, fontSize: 16),
        decoration: InputDecoration(
            suffixIcon:
                model.checkPasswordConditions && model.password.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(right: 0),
                        child: Icon(Icons.check, color: globals.primaryColor))
                    : Padding(
                        padding: EdgeInsets.only(right: 0),
                        child: Icon(Icons.clear, color: globals.grey)),
            labelText: AppLocalizations.of(context).enterPassword,
            prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
            labelStyle: Theme.of(context).textTheme.headline5,
            helperStyle: Theme.of(context).textTheme.headline5));
  }

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------

                                    Widget Confirm Password

--------------------------------------------------------------------------------------------------------------------------------------------------------------*/

  Widget _buildConfirmPasswordTextField(model) {
    return TextField(
        onChanged: (String pass) {
          setState(() {
            model.checkConfirmPassword(pass);
          });
        },
        controller: _confirmPassTextController,
        obscureText: true,
        maxLength: 16,
        style: model.checkConfirmPasswordConditions
            ? TextStyle(color: globals.primaryColor, fontSize: 16)
            : TextStyle(color: globals.grey, fontSize: 16),
        decoration: InputDecoration(
            suffixIcon: model.checkConfirmPasswordConditions &&
                    model.confirmPassword.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.only(right: 0),
                    child: Icon(Icons.check, color: globals.primaryColor))
                : Padding(
                    padding: EdgeInsets.only(right: 0),
                    child: Icon(Icons.clear, color: globals.grey)),
            labelText: AppLocalizations.of(context).confirmPassword,
            prefixIcon: Icon(Icons.lock, color: Colors.white),
            labelStyle: Theme.of(context).textTheme.headline5,
            helperStyle: Theme.of(context).textTheme.headline5));
  }

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------

                                    Widget Create New Wallet Button

--------------------------------------------------------------------------------------------------------------------------------------------------------------*/

  Widget _buildCreateNewWalletButton(model, BuildContext context) {
    return ButtonTheme(
      shape:
          RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30)),
      minWidth: double.infinity,
      child: MaterialButton(
        padding: EdgeInsets.all(15),
        color: globals.primaryColor,
        textColor: Colors.white,
        onPressed: () async {
          log.e('Random Mnemonic - ${widget.randomMnemonicFromRoute}');
          // Remove the on screen keyboard by shifting focus to unused focus node
          FocusScope.of(context).requestFocus(FocusNode());
          var passSuccess = model.validatePassword(
              _passTextController.text, _confirmPassTextController.text);

          _passTextController.text = '';
          _confirmPassTextController.text = '';
          model.errorMessage = '';
          if (passSuccess) {
            await model.createOfflineWallets();
          }
        },
        child: Text(
          AppLocalizations.of(context).createWallet,
          style: Theme.of(context).textTheme.button,
        ),
      ),
    );
  }
}
