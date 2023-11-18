import 'dart:async';

import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/spend/spend_state.dart';
import 'package:anon_wallet/utils/app_haptics.dart';
import 'package:anon_wallet/utils/parsers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QRScannerView extends StatefulWidget {
  final Function(QRResult value) onScanCallback;

  const QRScannerView({super.key, required this.onScanCallback});

  @override
  State<StatefulWidget> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: FloatingActionButton.extended(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        splashColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.pop(context);
        },
        label: const Text("Close"),
        icon: const Icon(Icons.close),
      ),
      body: _buildQrView(context),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return CameraView(
      callBack: (value) async {
        if (kDebugMode) {
          print(
              "qr_scanner.dart: CameraView: callBack: value.text: ${value.text}");
        }
        if (!isScanned) {
          AppHaptics.lightImpact();
          widget.onScanCallback(value);
          Navigator.pop(context, value);
          isScanned = true;
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

PersistentBottomSheetController showQRBottomSheet(BuildContext context,
    {Function(QRResult value)? onScanCallback,
    UrType? urType,
    String? importTitle}) {
  Completer<QRResult> completer = Completer();

  return showBottomSheet(
      context: context,
      builder: (context) {
        return HookConsumer(
          builder: (context, ref, c) {
            ValueNotifier<bool> progress = useState(false);
            return Stack(
              children: [
                Positioned.fill(
                  child: QRScannerView(
                    onScanCallback: (value) {
                      onScanCallback?.call(value);
                      AppHaptics.lightImpact();
                      if (value.type == QRResultType.text &&
                          value.text.isNotEmpty) {
                        var parsedAddress = Parser.parseAddress(value.text);
                        if (parsedAddress[0] != null) {
                          ref.read(addressStateProvider.state).state =
                              parsedAddress[0];
                        }
                        if (parsedAddress[1] != null) {
                          ref.read(amountStateProvider.state).state =
                              parsedAddress[1];
                        }
                        if (parsedAddress[2] != null) {
                          ref.read(notesStateProvider.state).state =
                              parsedAddress[2];
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      });
}
