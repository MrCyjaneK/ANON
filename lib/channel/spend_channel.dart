import 'package:anon_wallet/anon_wallet.dart';
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


  Future<bool?> importTxFile(String filename,String type) async {
    bool? value = await platform
        .invokeMethod("importTxFile", {"filePath": filename,"type":type});
    return value;
  }


  dynamic compose(String amount, String address, String notes) async {
    return await platform.invokeMethod("composeTransaction",
        {"amount": amount, "address": address, "notes": notes});
  }

  dynamic composeAndBroadcast(
      String amount, String address, String notes) async {
    return await platform.invokeMethod("composeAndBroadcast",
        {"amount": amount, "address": address, "notes": notes});
  }

  Future<Map> composeAndSave(
      String amount, String address, String notes) async {
    return await platform.invokeMethod(
      "composeAndSave",
      {
        "amount": amount,
        "sign": (!isViewOnly && isAirgapEnabled),
        "address": address,
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
