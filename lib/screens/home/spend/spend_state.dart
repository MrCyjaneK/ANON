import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/models/broadcast_tx_state.dart';
import 'package:anon_wallet/utils/app_haptics.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

  createPreview(String amount, String address, bool sweepAll, String notes,
      List<String> keyImages) async {
    if (keyImages.isEmpty) {
      print("WARN: keyImages is empty. Filling with all keys");
      final value = await WalletChannel().getUtxos();
      final tmpval = [];
      value.forEach((key, value) {
        if (!value["spent"]) {
          tmpval.add(value);
        }
      });
      print("${value.length} vs ${tmpval.length}");
      List<String> outs = [];
      // num maxAmt = 0;
      for (var output in tmpval) {
        outs.add(output["keyImage"]);
        // maxAmt += output["amount"];
      }
      print(outs);
      keyImages = outs;
    }
    if (kDebugMode) {
      print('createPreview(');
      print('\tamount: $amount');
      print('\taddress: $address');
      print('\tnotes: $notes');
      print("\tkeyImages: $keyImages");
      print(")");
    }
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    try {
      var returnValue = await SpendMethodChannel()
          .compose(amount, address, sweepAll, notes, keyImages);
      print(returnValue);
      if (returnValue["errorString"] != null &&
          returnValue["errorString"] != "") {
        // Apparently setting only errorString doesn't cause state to properly
        // reload.
        state = TxState()..errorString = returnValue["errorString"];
      } else {
        state = TxState.fromJson(returnValue);
        print(state);
      }
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      print(e);
    }
  }

  broadcast(String amount, String address, bool sweepAll, String notes,
      List<String> keyImages) async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    var returnValue = await SpendMethodChannel()
        .composeAndBroadcast(amount, address, sweepAll, notes, keyImages);
    state = TxState.fromJson(returnValue);
    AppHaptics.mediumImpact();
    AppHaptics.mediumImpact();
  }

  Future composeAndSave(String amount, String address, bool sweepAll,
      String notes, List<String> keyImages) async {
    var broadcastState = TxState();
    broadcastState.state = "waiting";
    state = broadcastState;
    var returnValue = await SpendMethodChannel()
        .composeAndSave(amount, address, sweepAll, notes, keyImages);
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
