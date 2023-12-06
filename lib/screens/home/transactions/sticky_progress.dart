import 'dart:async';

import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/utils/json_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SyncProgressSliver extends SingleChildRenderObjectWidget {
  const SyncProgressSliver({super.key})
      : super(child: const ProgressSliverWidget());

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ProgressStickyRender();
  }
}

class ProgressSliverWidget extends ConsumerStatefulWidget {
  const ProgressSliverWidget({super.key});

  @override
  ProgressSliverWidgetState createState() => ProgressSliverWidgetState();
}

class ProgressSliverWidgetState extends ConsumerState<ProgressSliverWidget> {
  @override
  void initState() {
    loadTimer();
    super.initState();
  }

  bool isSynchronized = true;

  void loadTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final newIsSynchronized = await WalletChannel().isSynchronized();
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        isSynchronized = newIsSynchronized;
      }); // Trigger
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isConnecting = ref.watch(connectingToNodeStateProvider);
    bool isWalletOpening = ref.watch(walletLoadingProvider) ?? true;
    bool connected = ref.watch(connectionStatus) ?? false;
    Map<String, num>? sync = ref.watch(syncProgressStateProvider);
    bool isActive = kDebugMode ||
        (sync != null && sync['remaining'] != 0) ||
        (isConnecting || isWalletOpening) ||
        (!connected);

    double height = (sync != null || kDebugMode) ? 44 : 14;

    return AnimatedContainer(
      color: Theme.of(context).scaffoldBackgroundColor,
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: isActive ? height : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Builder(
          builder: (context) {
            if (sync != null && sync['remaining'] != 0) {
              if (kDebugMode) {
                return (const SelectableText(
                    "(sync != null && sync['remaining'] != 0)"));
              }
              double progress = sync['progress']?.toDouble() ?? 0.0;
              return SizedBox(
                height: 28,
                child: Column(
                  children: [
                    RoundedLinearProgressBar(
                      max: 1,
                      height: 4,
                      current: sync['progress']?.toDouble() ?? 0.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${sync['remaining']} blocks remaining",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (isConnecting || isWalletOpening) {
              if (kDebugMode) {
                return (const SelectableText(
                    "(isConnecting || isWalletOpening)"));
              }
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0xFA2A2A2A),
                      minHeight: 4,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  Text(
                    "Connecting...",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            } else if (!isSynchronized) {
              if (kDebugMode) {
                return (const SelectableText("(!isSynchronized)"));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0xFA2A2A2A),
                      minHeight: 4,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  Text(
                    "Connecting...",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            } else if (!connected) {
              if (kDebugMode) {
                return (const SelectableText("(!connected)"));
              }
              return Column(
                children: [
                  const LinearProgressIndicator(
                    minHeight: 4,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  Text(
                    "Disconnected",
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                ],
              );
            } else {
              if (kDebugMode) return (const SelectableText("Connected!"));
              return Container();
            }
          },
        ),
      ),
    );
  }
}

class ProgressStickyRender extends RenderSliverSingleBoxAdapter {
  @override
  void performLayout() {
    var constraints = this.constraints;
    geometry = SliverGeometry.zero;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtend = child?.size.height ?? 0;
    geometry = SliverGeometry(
      paintExtent: childExtend,
      maxPaintExtent: childExtend,
      paintOrigin: constraints.scrollOffset,
    );
    setChildParentData(child!, constraints, geometry!);
  }
}

class RoundedLinearProgressBar extends StatelessWidget {
  final double max;
  final double current;
  final double height;

  const RoundedLinearProgressBar({
    super.key,
    required this.max,
    required this.current,
    this.height = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, boxConstraints) {
        var x = boxConstraints.maxWidth;
        var percent = (current / max) * x;
        return Stack(
          children: [
            Container(
              width: x,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFA2A2A2A),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: percent,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ],
        );
      },
    );
  }
}
