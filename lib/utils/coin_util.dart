import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:exchangilymobileapp/utils/fab_util.dart';

import '../packages/bip32/bip32_base.dart' as bip32;
import 'package:bitcoin_flutter/src/models/networks.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bitcoin_flutter/src/bitcoin_flutter_base.dart';
import '../utils/string_util.dart';
import '../environments/environment.dart';
import './btc_util.dart';
import './eth_util.dart';
import "package:pointycastle/pointycastle.dart";
import 'dart:typed_data';
import 'dart:convert';
import 'package:bitcoin_flutter/src/bitcoin_flutter_base.dart';
import 'package:web3dart/crypto.dart';
encodeSignature(signature, recovery, compressed, segwitType) {
  if (segwitType != null) {
    recovery += 8;
    if (segwitType == 'p2wpkh') recovery += 4;
  } else {
    if (compressed) recovery += 4;
  }
  recovery += 27;
  return recovery.toRadixString(16) ;
}

/*
Future signedBitcoinMessage(String originalMessage, String wif) async {
  print('originalMessage=');
  print(originalMessage);
  var hdWallet = Wallet.fromWIF(wif);
  var compressed = false;
  var sigwitType;
  var signedMess = await hdWallet.sign(originalMessage);
  var recovery = 0;
  var r = encodeSignature(signedMess, recovery, compressed, sigwitType);
  print('r=');
  print(r);
  print('signedMess=');
  print(signedMess);
  return signedMess;
}
*/

const _ethMessagePrefix = '\u0019Ethereum Signed Message:\n';
const _btcMessagePrefix = '\x18Bitcoin Signed Message:\n';
Uint8List uint8ListFromList(List<int> data) {
  if (data is Uint8List) return data;

  return Uint8List.fromList(data);
}

Uint8List _padTo32(Uint8List data) {
  assert(data.length <= 32);
  if (data.length == 32) return data;

  // todo there must be a faster way to do this?
  return Uint8List(32)..setRange(32 - data.length, 32, data);
}

Future<Uint8List> signPersonalMessageWith(String _messagePrefix, Uint8List privateKey, Uint8List payload, {int chainId}) async {
  final prefix = _messagePrefix + payload.length.toString();
  final prefixBytes = ascii.encode(prefix);

  // will be a Uint8List, see the documentation of Uint8List.+
  final concat = uint8ListFromList(prefixBytes + payload);

  //final signature = await credential.signToSignature(concat, chainId: chainId);

  var  signature = sign(keccak256(concat), privateKey);

  // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
  // be aware that signature.v already is recovery + 27
  final chainIdV =
  chainId != null ? (signature.v - 27 + (chainId * 2 + 35)) : signature.v;

  signature = MsgSignature(signature.r, signature.s, chainIdV);


  final r = _padTo32(intToBytes(signature.r));
  final s = _padTo32(intToBytes(signature.s));
  final v = intToBytes(BigInt.from(signature.v));

  // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L63
  return uint8ListFromList(r + s + v);
  //return credential.sign(concat, chainId: chainId);
}

signedMessage(String originalMessage, seed, coinName, tokenType) async {
  print('originalMessage=');
  print(originalMessage);
  var r = '';
  var s = '';
  var v = '';

  final root = bip32.BIP32.fromSeed(
      seed,
      bip32.NetworkType(
          wif: environment["chains"]["BTC"]["network"].wif,
          bip32: new bip32.Bip32Type(
              public: environment["chains"]["BTC"]["network"].bip32.public, private: environment["chains"]["BTC"]["network"].bip32.private)));

  var signedMess;
  if (coinName == 'ETH' || tokenType == 'ETH') {
    var coinType = environment["CoinType"]["ETH"];
    final ethCoinChild = root.derivePath("m/44'/"+ coinType.toString() + "'/0'/0/0");
    var privateKey = ethCoinChild.privateKey;
    //var credentials = EthPrivateKey.fromHex(privateKey);
    var credentials = EthPrivateKey(privateKey);


    var signedMessOrig = await credentials
        .signPersonalMessage(stringToUint8List(originalMessage));

    signedMess = await signPersonalMessageWith(_ethMessagePrefix, privateKey, stringToUint8List(originalMessage));
    String ss = HEX.encode(signedMess);
    String ss2 = HEX.encode(signedMessOrig);
    if (ss == ss2) {
      print('signiture is right');
    } else {
      print('signiture is wrong');
    }
    r = ss.substring(0, 64);
    s = ss.substring(64, 128);
    v = ss.substring(128);
  } else if (coinName == 'FAB' || coinName == 'BTC' || tokenType == 'FAB') {
    //var hdWallet = new HDWallet.fromSeed(seed, network: testnet);

    var coinType = environment["CoinType"]["FAB"];
    if (coinName == 'BTC') {
      coinType = environment["CoinType"]["BTC"];
    }

    var bitCoinChild = root.derivePath("m/44'/"+ coinType.toString() + "'/0'/0/0");
    //var btcWallet =
    //    hdWallet.derivePath("m/44'/" + coinType.toString() + "'/0'/0/0");
    var privateKey = bitCoinChild.privateKey;
    var credentials = EthPrivateKey(privateKey);


    signedMess = await signPersonalMessageWith(_btcMessagePrefix, privateKey, stringToUint8List(originalMessage));
    String ss = HEX.encode(signedMess);
    r = ss.substring(0, 64);
    s = ss.substring(64, 128);
    v = ss.substring(128);
    /*
    var btcWallet = new HDWallet.fromBase58(bitCoinChild.toBase58(), network: environment["chains"]["BTC"]["network"]);
    print('privateKey=');
    print(HEX.decode(btcWallet.privKey));
    signedMess = await btcWallet.sign(originalMessage);
    var recovery = 0;
    var compressed = true;
    var sigwitType;
    v = encodeSignature(signedMess, recovery, compressed, sigwitType);
    String ss = HEX.encode(signedMess);
    r = ss.substring(0, 64);
    s = ss.substring(64, 128);

     */
  }

  if (signedMess != null) {


  }

  return {'r': r, 's': s, 'v': v};
}

getOfficalAddress(String coinName) {
  var address = environment['addresses']['exchangilyOfficial']
      .where((addr) => addr['name'] == coinName)
      .toList();


  if (address != null) {
    return address[0]['address'];
  }
  return null;
}

/*
usage:
getAddressForCoin(root, 'BTC');
getAddressForCoin(root, 'ETH');
getAddressForCoin(root, 'FAB');
getAddressForCoin(root, 'USDT', tokenType: 'ETH');
getAddressForCoin(root, 'EXG', tokenType: 'FAB');
 */
Future getAddressForCoin(root, coinName, {tokenType = '', index = 0}) async {
  if (coinName == 'BTC') {
    var node = getBtcNode(root, index: index);
    return getBtcAddressForNode(node);
  } else if ((coinName == 'ETH') || (tokenType == 'ETH')) {
    var node = getEthNode(root, index: index);
    return await getEthAddressForNode(node);
  } else if (coinName == 'FAB') {
    var node = getFabNode(root, index: index);
    return getBtcAddressForNode(node);
  } else if (tokenType == 'FAB') {
    var node = getFabNode(root, index: index);
    var fabPublicKey = node.publicKey;
    Digest sha256 = new Digest("SHA-256");
    var pass1 = sha256.process(fabPublicKey);
    Digest ripemd160 = new Digest("RIPEMD-160");
    var pass2 = ripemd160.process(pass1);
    var fabTokenAddr = '0x' + HEX.encode(pass2);
    return fabTokenAddr;
  }
  return '';
}

Future getBalanceForCoin(root, coinName, {tokenType = '', index = 0}) async {
  var address = await getAddressForCoin(root, coinName,
      tokenType: tokenType, index: index);
  if (coinName == 'BTC') {
    return await getBtcBalanceByAddress(address);
  } else if (coinName == 'ETH') {
    return await getEthBalanceByAddress(address);
  } else if (coinName == 'FAB') {
    return await getFabBalanceByAddress(address);
  } else if (tokenType == 'ETH') {
    return await getEthTokenBalanceByAddress(address, coinName);
  } else if (tokenType == 'FAB') {
    return await getFabTokenBalanceByAddress(address, coinName);
  }

  return {'balance': -1, 'lockbalance': -1};
}