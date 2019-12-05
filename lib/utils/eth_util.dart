import 'package:keccak/keccak.dart';
import "string_util.dart";
import 'package:web3dart/crypto.dart';
import 'package:hex/hex.dart';
import 'dart:typed_data';
getTransactionHash(Uint8List signTransaction) {

  /*
  input:
  f86c4f8502540be4008252089402c55515e62a0b25d2447c6d70369186b8f103598801aa535d3d0c0000802aa0da719ae9c04a8717f3b161430f3e4beb877dcc4c985d8184cad26251a09a2284a04dd5813739731a5d7c54f0fd620b12017d0409508d41166fbf622c38333b2af6
  expected output:
  0x86b43cb98c10dbb6474ca495d1939cb0526ad696adde2636f3c1500b2ba52a58

   */
  //txHex="f86c4f8502540be4008252089402c55515e62a0b25d2447c6d70369186b8f103598801aa535d3d0c0000802aa0da719ae9c04a8717f3b161430f3e4beb877dcc4c985d8184cad26251a09a2284a04dd5813739731a5d7c54f0fd620b12017d0409508d41166fbf622c38333b2af6";
  //print('txHex=');
  //print(txHex);
  var p = keccak(signTransaction);
  var hash = "0x" + HEX.encode(p);
  return hash;
}


/*
import 'package:web3dart/crypto.dart';
import 'package:hex/hex.dart';

var input = HEX.decode(txHex);
print(input);
print('haha');
var output = keccak256(input);

print(output);
print(HEX.encode(output));

 */