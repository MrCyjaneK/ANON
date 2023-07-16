import 'package:flutter/material.dart';

class CircleProgressWidget extends StatelessWidget {
  final String progressMessage;

  const CircleProgressWidget({super.key, required this.progressMessage});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(true);
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Spacer(),
            SizedBox.fromSize(
              size: const Size(280, 280),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                    ),
                  ),
                  Positioned.fill(
                      child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Image.asset("assets/anon_logo.png"),
                  )),
                ],
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Text(progressMessage,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
