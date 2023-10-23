import 'package:anon_wallet/models/config.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:flutter/services.dart';

enum WalletState {
  walletNotInitialized,
  //Wallet exist not connected to node
  walletCreated,
  //Wallet exist and connected to node
  walletReady
}

class WalletChannel {
  static const platform = MethodChannel('wallet.channel');
  static final WalletChannel _singleton = WalletChannel._internal();

  WalletChannel._internal();

  factory WalletChannel() {
    return _singleton;
  }

  Future<Wallet> create(String password, String seedPhrase) async {
    dynamic value = await platform.invokeMethod("create",
        {"name": "default", "password": password, "seedPhrase": seedPhrase});
    return Wallet.fromJson(value);
  }

  Future<void> rescan() async {
    await platform.invokeMethod("rescan");
  }

  Future<void> refresh() async {
    await platform.invokeMethod("refresh");
  }

  Future<Wallet?> openWallet(String password) async {
    dynamic value =
        await platform.invokeMethod("openWallet", {"password": password});
    return Wallet.fromJson(value);
  }

  Future<String?> getTxKey(String txId) async {
    String? value = await platform.invokeMethod("getTxKey", {"txId": txId});
    return value;
  }

  Future<String> exportOutputs(bool all) async {
    String value = await platform.invokeMethod("exportOutputs");
    return value;
  }

  Future<String?> importKeyImages(String filename) async {
    String? value =
        await platform.invokeMethod("importKeyImages", {"filename": filename});
    return value;
  }

  Future<void> setTrustedDaemon(bool arg) async {
    await platform.invokeMethod("setTrustedDaemon", {"arg": arg});
  }

  Future<String?> submitTransaction(String filename) async {
    String? value = await platform
        .invokeMethod("submitTransaction", {"filename": filename});
    return value;
  }

  Future<bool> setTxUserNotes(String txId, String notes) async {
    bool value = await platform
        .invokeMethod("setTxUserNotes", {"txId": txId, "message": notes});
    return value;
  }

  Future startSync() async {
    await platform.invokeMethod("startSync");
  }

  Future<WalletState> getWalletState() async {
    int value = await platform.invokeMethod("walletState");
    bool isViewOnly = await platform.invokeMethod("isViewOnly");
    anonConfigState.setWalletViewState(isViewOnly);
    if (value == 1) {
      return WalletState.walletCreated;
    }
    if (value == 2) {
      return WalletState.walletReady;
    }
    return WalletState.walletNotInitialized;
  }

  Future<Wallet> getWalletPrivate(String seedPassphrase) async {
    dynamic value = await platform
        .invokeMethod("viewWalletInfo", {"seedPassphrase": seedPassphrase});
    return Wallet.fromJson(value);
  }

  Future wipe(String seedPassphrase) async {
    return platform
        .invokeMethod("wipeWallet", {"seedPassphrase": seedPassphrase});
  }

  Future<String?> importOutputsJ(String filename) async {
    return await platform
        .invokeMethod("importOutputsJ", {"filename": filename});
  }

  Future<String> exportKeyImages() async {
    return await platform.invokeMethod("exportKeyImages");
  }

  Future<String?> signAndExportJ(String inputFile, String outputFile) async {
    return await platform.invokeMethod(
        "signAndExportJ", {"inputFile": inputFile, "outputFile": outputFile});
  }

  Future<Map> getUtxos() async {
    return await platform.invokeMethod("getUtxos", {});
  }

  Future lock() async {
    return platform.invokeMethod("lock");
  }

  Future<bool> importFromFile(UrType type, String path) async {
    return await platform.invokeMethod(
        "importFromFile", {"importType": type.type, "file": path});
  }

  Future<Wallet?> optimizeBattery() async {
    dynamic value = await platform.invokeMethod("optimizeBattery", {});
    return Wallet.fromJson(value);
  }
}
