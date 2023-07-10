import 'dart:async';

import 'package:anon_wallet/channel/node_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Proxy {
  String serverUrl = "";
  String portTor = "";
  String portI2p = "";

  Proxy();

  Proxy.fromJson(value) {
    serverUrl = value['proxyServer'] ?? "";
    portTor = value['proxyPortTor'] ?? "";
    portI2p = value['proxyPortI2p'] ?? "";
  }

  isConnected() {
    // TODO: this should actually check if you are connected.....
    return serverUrl.isNotEmpty && portI2p.isNotEmpty && portTor.isNotEmpty;
  }
}

class ProxyStateNotifier extends StateNotifier<Proxy> {
  ProxyStateNotifier(super.state);

  Future getState() async {
    state = await NodeChannel().getProxy();
  }

  Future setProxy(String proxy, String portTor, String portI2p) async {
    await NodeChannel().setProxy(proxy, portTor, portI2p);
    state = await NodeChannel().getProxy();
  }
}

class ViewWalletPrivateDetailsStateNotifier extends StateNotifier<Wallet?> {
  ViewWalletPrivateDetailsStateNotifier(super.state);

  Future getWallet(String seedPassphrase) async {
    state = await WalletChannel().getWalletPrivate(seedPassphrase);
  }

  clear() {
    state = null;
  }
}

final proxyStateProvider = StateNotifierProvider<ProxyStateNotifier, Proxy>(
    (ref) => ProxyStateNotifier(Proxy()));

final viewPrivateWalletProvider =
    StateNotifierProvider<ViewWalletPrivateDetailsStateNotifier, Wallet?>(
        (ref) => ViewWalletPrivateDetailsStateNotifier(null));
