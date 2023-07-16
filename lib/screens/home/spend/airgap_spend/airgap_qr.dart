import 'dart:math';
import 'dart:ui';

import 'package:anon_wallet/screens/home/spend/airgap_spend/airgap_state.dart';
import 'package:anon_wallet/widgets/qr_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AirGapQR extends ConsumerWidget {
  final bool showPlaceHolder;
  final URGenerateRequest? urGenerateRequest;

  const AirGapQR(
      {super.key, this.urGenerateRequest, this.showPlaceHolder = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var size =
        (MediaQuery.of(context).size.width * .8).clamp(300, 600).toDouble();
    return SizedBox.square(
      dimension: size,
      child: showPlaceHolder
          ? buildPlaceHolder(context, size)
          : buildQR(context, size, ref),
    );
  }

  buildPlaceHolder(BuildContext context, double size) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        QrImageView(
          backgroundColor: Colors.black,
          version: QrVersions.auto,
          size: size,
          embeddedImage: const AssetImage("assets/anon_logo.png"),
          gapless: true,
          eyeStyle: const QrEyeStyle(
              color: Colors.white, eyeShape: QrEyeShape.square),
          dataModuleStyle: const QrDataModuleStyle(
              color: Colors.white, dataModuleShape: QrDataModuleShape.square),
          data: String.fromCharCodes(
              List.generate(100, (index) => Random().nextInt(33) + 89)),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8.0,
              sigmaY: 8.0,
            ),
            child: SizedBox.square(dimension: size),
          ),
        ),
      ],
    );
  }

  buildQR(BuildContext context, double size, WidgetRef ref) {
    if (urGenerateRequest == null) {
      return SizedBox.square(dimension: size);
    }
    var qrAsync = ref.watch(generateURQR(urGenerateRequest!));
    return SizedBox.square(
      dimension: size,
      child: qrAsync.when(
        data: (data) {
          return SizedBox.square(
            dimension: size,
            child: CupertinoContextMenu(
              enableHapticFeedback: true,
              actions: [
                CupertinoContextMenuAction(
                    child: const Text('Save as file'), onPressed: () {})
              ],
              child: AnimatedQR(
                size: size,
                frames: QRFrames(data),
              ),
            ),
          );
        },
        error: (error, stackTrace) =>
            Text("Unable to create QR ${error.toString()}"),
        loading: () => const SizedBox(
          height: 80,
          width: 80,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
