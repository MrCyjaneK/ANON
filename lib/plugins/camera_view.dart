import 'dart:math';

import 'package:anon_wallet/utils/app_haptics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

typedef QRCallBack = Function(String text);

class CameraView extends StatefulWidget {
  final QRCallBack callBack;

  const CameraView({Key? key, required this.callBack}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

const anonCameraMethodChannel = MethodChannel('anon_camera');

class URQrProgress {
  int expectedPartCount;
  int processedPartsCount;
  List<int> receivedPartIndexes;
  double percentage;

  URQrProgress(this.expectedPartCount, this.processedPartsCount, this.receivedPartIndexes, this.percentage);

  bool equals(URQrProgress? progress) {
    if (progress == null) {
      return false;
    }
    return processedPartsCount == progress.processedPartsCount;
  }
}

class _CameraViewState extends State<CameraView> {
  static const platform = MethodChannel('anon_camera');
  static const eventChannel = EventChannel("anon_camera:events");
  int? id;
  bool? permissionGranted = null;
  double? width;
  double? height;
  URQrProgress? urQrProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      startCamera();
    });
  }

  void startCamera() async {
    bool? permission = await platform.invokeMethod<bool>("checkPermissionState");
    setState(() {
      permissionGranted = permission;
    });
    if (permission == true) {
      platform.invokeMethod<Map>("startCam");
    } else {
      platform.invokeMethod<Map>("requestPermission");
    }
    eventChannel.receiveBroadcastStream().listen((event) {
      if (event['id'] != null) {
        permissionGranted = true;
        setState(() {
          id = event["id"];
          width = event["width"];
          height = event["height"];
        });
      }
      if (event['expectedPartCount'] != null) {
        URQrProgress progress = URQrProgress(
            event['expectedPartCount'],
            event['processedPartsCount'],
            event['receivedPartIndexes'] != null ? List<int>.from(event['receivedPartIndexes']) : [],
            event['estimatedPercentComplete']);
        if (!progress.equals(urQrProgress)) {
          AppHaptics.lightImpact();
          setState(() {
            urQrProgress = progress;
          });
        }
      }
      if (event["result"] != null) {
        platform.invokeMethod<Map>("stopCam");
        widget.callBack(event["result"]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (permissionGranted == false) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("To capture QR code, allow ANON to access your camera",
                    style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
              ),
              const Padding(padding: EdgeInsets.all(6)),
              TextButton(
                  onPressed: () {
                    platform.invokeMethod<Map>("requestPermission");
                  },
                  child: const Text("Allow camera"))
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ClipRect(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: id != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: width!,
                        height: height!,
                        child: Texture(textureId: id!, filterQuality: FilterQuality.medium),
                      ),
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.qrcode_viewfinder,
                          size: 68,
                        )
                      ],
                    ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.all(68),
          child: SvgPicture.asset("assets/scanner_frame.svg", color: Colors.white24),
        ),
        urQrProgress != null
            ? Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(68),
                alignment: Alignment.center,
                child: SizedBox.square(
                    dimension: 200, child: CustomPaint(painter: ProgressPainter(urQrProgress: urQrProgress!))),
              )
            : const SizedBox(),
        urQrProgress != null
            ? Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(68),
                alignment: Alignment.center,
                child: Center(
                  child: Text(
                    "${urQrProgress?.processedPartsCount ?? "N"}/${urQrProgress?.expectedPartCount ?? "A"} ",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  @override
  void dispose() {
    platform.invokeMethod<Map>("stopCam");
    super.dispose();
  }
}

class ProgressPainter extends CustomPainter {
  final URQrProgress urQrProgress;

  ProgressPainter({required this.urQrProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2.0, size.height / 2.0);
    final radius = size.width * 0.9;
    final rect = Rect.fromCenter(center: c, width: radius, height: radius);
    const fullAngle = 360.0;
    var startAngle = 0.0;
    for (int i = 0; i < urQrProgress.expectedPartCount.toInt(); i++) {
      var sweepAngle = (1 / urQrProgress.expectedPartCount) * fullAngle * pi / 180.0;
      drawSector(canvas, urQrProgress.receivedPartIndexes.contains(i), rect, startAngle, sweepAngle);
      startAngle += sweepAngle;
    }
  }

  void drawSector(Canvas canvas, bool isActive, Rect rect, double startAngle, double sweepAngle) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = isActive ? const Color(0xffff6600) : Colors.white70;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return urQrProgress != oldDelegate.urQrProgress;
  }
}
