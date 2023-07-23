import 'dart:io';

import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/models/broadcast_tx_state.dart';
import 'package:anon_wallet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class SpendValidationNotifier extends ChangeNotifier {
  bool? validAddress;
  bool? validAmount;

  Future<bool> validate(String amount, String address) async {
    dynamic response =
        await SpendMethodChannel().validateAddress(amount, address);
    validAddress = response['address'] == true;
    validAmount = response['amount'] == true;
    notifyListeners();
    return validAddress == true && validAmount == true;
  }

  clear() {
    validAddress = null;
    validAmount = null;
    notifyListeners();
  }
}

class TransactionStateNotifier extends StateNotifier<TxState> {
  TransactionStateNotifier() : super(TxState());

  createPreview(String amount, String address, String notes) async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    try {
      var returnValue =
          await SpendMethodChannel().compose(amount, address, notes);
      final newState = TxState.fromJson(returnValue);
      state = newState;
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      print(e);
    }
  }

  Future broadcast(String amount, String address, String notes) async {
    var broadcastState = TxState();

    if (isViewOnly) {
      broadcastState.state = "unsignedtx-waiting";
      state = broadcastState;

      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final fpath = "${appDocumentsDir.path}/unsigned_monero_tx";
      if (await File(fpath).exists()) {
        await File(fpath).delete();
      }
      var returnValue =
          await SpendMethodChannel().composeAndSave(amount, address, notes);
      state = TxState.fromJson(returnValue);
      AppHaptics.mediumImpact();
    } else {
      broadcastState.state = "waiting";
      state = broadcastState;

      var returnValue = await SpendMethodChannel()
          .composeAndBroadcast(amount, address, notes);
      state = TxState.fromJson(returnValue);
      AppHaptics.mediumImpact();
    }
    //AppHaptics.mediumImpact();
  }

  Future broadcastSigned() async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    var returnValue = await SpendMethodChannel().broadcastSigned();
    state = TxState.fromJson(returnValue);
    AppHaptics.mediumImpact();
    AppHaptics.mediumImpact();
  }

  Future composeAndSave(String amount, String address, String notes) async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    var returnValue =
        await SpendMethodChannel().composeAndSave(amount, address, notes);
    state = TxState.fromJson(returnValue);
  }

  Future loadUnSignedTx() async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    var returnValue = await SpendMethodChannel().loadUnsignedTx();
    state = TxState.fromJson(returnValue);
  }

  Future signUnSigned() async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    var returnValue = await SpendMethodChannel().signUnsignedTx();
    state = TxState.fromJson(returnValue);
  }
}

final transactionStateProvider =
    StateNotifierProvider<TransactionStateNotifier, TxState>(
        (ref) => TransactionStateNotifier());

final validationProvider =
    ChangeNotifierProvider((ref) => SpendValidationNotifier());

final addressStateProvider = StateProvider((ref) => "");
final amountStateProvider = StateProvider((ref) => "");
final notesStateProvider = StateProvider((ref) => "");
final lockMainButtonProvider = StateProvider((ref) => false);
