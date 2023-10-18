import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:flutter/services.dart';

class SpendMethodChannel {
  static const platform = MethodChannel('spend.channel');
  static final SpendMethodChannel _singleton = SpendMethodChannel._internal();

  SpendMethodChannel._internal();

  factory SpendMethodChannel() {
    return _singleton;
  }

  dynamic validateAddress(String amount, String address) async {
    return await platform
        .invokeMethod("validate", {"amount": amount, "address": address});
  }

  Future<Map> signUnsignedTx() async {
    return await platform.invokeMethod("signUnsignedTx");
  }

  Future<Map> broadcastSigned() async {
    return await platform.invokeMethod("broadcastSigned");
  }

  Future<Map> loadUnsignedTx() async {
    return await platform.invokeMethod("loadUnsignedTx");
  }

  Future<bool?> importTxFile(String filename, String type) async {
    bool? value = await platform
        .invokeMethod("importTxFile", {"filePath": filename, "type": type});
    return value;
  }

  dynamic compose(
    String amount,
    String address,
    bool sweepAll,
    String notes,
    List<String> keyImages,
  ) async {
    return await platform.invokeMethod("composeTransaction", {
      "amount": amount,
      "address": address,
      "sweepAll": sweepAll,
      "notes": notes,
      "keyImages": keyImages.join(",")
    });
  }

  Future<dynamic> composeAndBroadcast(
    String amount,
    String address,
    bool sweepAll,
    String notes,
    List<String> keyImages,
  ) async {
    if (keyImages.isEmpty) {
      keyImages = await getAllKeyImages();
    }
    return await platform.invokeMethod("composeAndBroadcast", {
      "amount": amount,
      "address": address,
      "sweepAll": sweepAll,
      "notes": notes,
      "keyImages": keyImages.join(",")
    });
  }

  Future<List<String>> getAllKeyImages() async {
    final value = await WalletChannel().getUtxos();
    final tmpval = [];
    value.forEach((key, value) {
      if (!value["spent"]) {
        tmpval.add(value);
      }
    });
    List<String> outs = [];
    // num maxAmt = 0;
    for (var output in tmpval) {
      outs.add(output["keyImage"]);
      // maxAmt += output["amount"];
    }
    return outs;
  }

  Future<Map> composeAndSave(String amount, String address, bool sweepAll,
      String notes, List<String> keyImages) async {
    if (keyImages.isEmpty) {
      keyImages = await getAllKeyImages();
    }
    return await platform.invokeMethod(
      "composeAndSave",
      {
        "amount": amount,
        "sweepAll": sweepAll,
        "sign": (!isViewOnly && isAirgapEnabled),
        "address": address,
        "keyImages": keyImages.join(","),
        "notes": notes
      },
    );
  }

  Future<String> getFilePath(UrType type) async {
    return await platform.invokeMethod(
      "getExportPath",
      {"type": type.type},
    );
  }
}
