import 'dart:io';

import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:anon_wallet/models/broadcast_tx_state.dart';
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
      state = TxState.fromJson(returnValue);
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      print(e);
    }
  }

  broadcast(String amount, String address, String notes) async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final fpath = "${appDocumentsDir.path}/unsigned_monero_tx";
    if (await File(fpath).exists()) {
      await File(fpath).delete();
    }
    var returnValue = await SpendMethodChannel()
        .composeAndSave(amount, address, notes, fpath);
    print("----returnValue compose");
    print(returnValue);
    state = TxState.fromJson(returnValue..addAll({"isLocal": true}));
    print("----returnValue compose");
    await BackUpRestoreChannel().exportFile(fpath);
    //AppHaptics.mediumImpact();
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
