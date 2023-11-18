import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:anon_wallet/anon_wallet.dart';
import 'package:crypt/crypt.dart';

Crypt VIEWONLY_walletpin = Crypt.sha512(
  base64Encode(
    List<int>.generate(64, (i) => Random.secure().nextInt(255)),
  ),
  rounds: 1,
); // just a temporary password

void storePassword(String pin) {
  if (!isViewOnly) {
    print("This function must not be called in non-viewonly wallet, exiting.");
    exit(1);
  }
  VIEWONLY_walletpin = Crypt.sha512(pin);
}
