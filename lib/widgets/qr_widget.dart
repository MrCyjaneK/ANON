import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AnimatedQR extends StatefulWidget {
  final QRFrames frames;
  final int fps;

  const AnimatedQR({super.key, this.fps = 5, required this.frames});

  @override
  State<AnimatedQR> createState() => _QRState();
}

class QRFrames {
  List<String> frames;
  int index = 0;

  QRFrames(this.frames);

  String get next => frames[index++ % frames.length];

  int get length => frames.length;

  int indexOf(String frame) => frames.indexOf(frame);
}

class _QRState extends State<AnimatedQR> {
  late Timer _timer;

  void startTimer() {
    var duration = Duration(milliseconds: 1000 ~/ widget.fps);
    if (widget.frames.length != 1) {
      _timer = Timer.periodic(duration, (Timer timer) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      backgroundColor: Colors.black,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(color: Colors.white, eyeShape: QrEyeShape.square),
      dataModuleStyle: const QrDataModuleStyle(
          color: Colors.white,
          dataModuleShape: QrDataModuleShape.square
      ),
      data: widget.frames.next,
    );
  }
}
