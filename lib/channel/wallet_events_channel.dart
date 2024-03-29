import 'dart:async';

import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/models/sub_address.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/utils/embed_tor.dart';
import 'package:anon_wallet/utils/json_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool debugWalletEventsChannel =
    false; // NOTE: set this to true to get that spammy logs

class WalletEventsChannel {
  static const channel = EventChannel("wallet.events");
  // ignore: unused_field
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
          debugPrint("walletEventsChannel: Sync:$type $event");
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
              if (kDebugMode) {
                setStats(
                  'DEBUG: ${event['isConnected']} | ${event['height']} | tor: ${proc == null}',
                );
              } else {
                // offline wallet check
                if (event['height'] == 1) {
                  setStats("Status: OFFLINE");
                  return;
                }
                String torInfo = "";
                if (proc != null) {
                  torInfo = "[Embedded Tor]";
                }
                if (event['isConnected'] == true) {
                  setStats('Synced: ${event['height']} $torInfo');
                } else {
                  setStats("Connecting... $torInfo");
                }
              }
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
