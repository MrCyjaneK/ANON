import 'dart:async';

import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/models/sub_address.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool debugWalletEventsChannel =
    false; // NOTE: set this to true to get that spammy logs

class WalletEventsChannel {
  static const channel = EventChannel("wallet.events");
  late StreamSubscription _events;
  final StreamController<Node?> _nodeStream = StreamController<Node?>();
  final StreamController<Wallet?> _walletStream = StreamController<Wallet?>();
  final StreamController<bool> _walletOpenStateStream =
      StreamController<bool>();
  final StreamController<List<SubAddress>> _subAddressesStream =
      StreamController<List<SubAddress>>();
  static final WalletEventsChannel _singleton = WalletEventsChannel._internal();

  Stream<Node?> nodeStream() {
    return _nodeStream.stream.asBroadcastStream();
  }

  Stream<Wallet?> walletStream() {
    return _walletStream.stream.asBroadcastStream();
  }

  Stream<List<SubAddress>> subAddresses() {
    return _subAddressesStream.stream.asBroadcastStream();
  }

  Stream<bool> walletOpenStream() {
    return _walletOpenStateStream.stream.asBroadcastStream();
  }

  WalletEventsChannel._internal() {
    initEventChannel();
  }

  initEventChannel() {
    _events =
        channel.receiveBroadcastStream().asBroadcastStream().listen((event) {
      try {
        var type = event['EVENT_TYPE'];
        if (debugWalletEventsChannel) {
          print("Sync:$type $event");
        }
        switch (type) {
          case "NODE":
            {
              _nodeStream.sink.add(Node.fromJson(event));
              break;
            }
          case "WALLET":
            {
              _walletStream.sink.add(Wallet.fromJson(event));
              break;
            }
          case "SUB_ADDRESSES":
            {
              List<SubAddress> addresses = [];
              try {
                event['addresses'].forEach((item) {
                  addresses.add(SubAddress.fromJson(item));
                });
              } catch (e, s) {
                debugPrintStack(stackTrace: s);
              }
              _subAddressesStream.sink.add(addresses);
              break;
            }
          case "OPEN_WALLET":
            {
              bool isLoading = event['state'];
              _walletOpenStateStream.sink.add(isLoading);
              break;
            }
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    });
  }

  factory WalletEventsChannel() {
    return _singleton;
  }
}
