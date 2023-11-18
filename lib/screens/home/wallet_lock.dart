import 'dart:async';

import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/main.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/screens/set_pin_screen.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/viewonly_cachepin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math' as math;

final walletLockProvider = FutureProvider((ref) => WalletChannel().lock());

class WalletLock extends ConsumerWidget {
  const WalletLock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockAsync = ref.watch(walletLockProvider);

    return Scaffold(
      body: Center(
        child: lockAsync.isLoading
            ? Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Hero(
                        tag: "lock",
                        child: Icon(Icons.lock,
                            size: (MediaQuery.of(context).size.width / 3.5)),
                      ),
                      const SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Closing wallet",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  )
                ],
              )
            : lockAsync.error != null
                ? Text(
                    (lockAsync.error is PlatformException)
                        ? "${(lockAsync.error as PlatformException).message}"
                        : (lockAsync.error as TypeError).stackTrace.toString(),
                  )
                : const LockedWallet(),
      ),
    );
  }
}

class LockedWallet extends StatefulWidget {
  const LockedWallet({super.key});

  @override
  State<LockedWallet> createState() => _LockedWalletState();
}

class _LockedWalletState extends State<LockedWallet> {
  String? error;
  String pin = "";
  String status = "LOCKED";
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Hero(
                tag: "anon_logo",
                child: SizedBox(
                    width: 180, child: Image.asset("assets/anon_logo.png")),
              ),
              const Text("LOCKED"),
              const Padding(padding: EdgeInsets.symmetric(vertical: 6)),
              AnimatedOpacity(
                opacity: error == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  error ?? "",
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.red),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4)),
              Expanded(
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: Consumer(
                    builder: (context, ref, c) {
                      return NumberPadWidget(
                        maxPinSize: maxPinSize,
                        onKeyPress: (String key, String newPin) {
                          setState(() {
                            pin = newPin;
                          });
                          setState(() {
                            error = null;
                          });
                        },
                        minPinSize: minPinSize,
                        onSubmit: (String pin) =>
                            unlockWallet(pin, AfterSelectAction.actionNone),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 42),
                child: Row(
                  children: [
                    const Spacer(),
                    InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () =>
                          unlockWallet(pin, AfterSelectAction.actionReceive),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(math.pi),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationX(math.pi),
                          child: const Icon(
                            Icons.arrow_outward,
                            size: 75,
                            color: null,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      onTap: () =>
                          unlockWallet(pin, AfterSelectAction.actionSend),
                      child: Icon(
                        Icons.arrow_outward,
                        size: 75,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      onWillPop: () => Future.value(false),
    );
  }

  void unlockWallet(String pin, AfterSelectAction action) async {
    setState(() {
      status = "UNLOCKING";
    });
    if (isViewOnly) {
      if (VIEWONLY_walletpin.match(pin)) {
        scheduleAutolockTimer();
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (c) => WalletHome(startScreen: getStartScreen(action)),
                settings: const RouteSettings(name: "/")),
            (route) => false);
        return;
      } else {
        setState(() {
          error = "Invalid pin";
          status = "LOCKED";
        });
        return;
      }
    }
    bool result = false;
    try {
      final resp = await WalletChannel().unlock(pin);
      result = (resp) == "Unlocked";
      if (result == false) {
        setState(() {
          error = "Unable to unlock.";
          status = "LOCKED";
        });
        return;
      }
      if (!mounted) return;
      scheduleAutolockTimer();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (c) => WalletHome(startScreen: getStartScreen(action)),
              settings: const RouteSettings(name: "/")),
          (route) => false);
    } catch (e) {
      setState(() {
        error = "Invalid password";
        status = "LOCKED";
      });
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 60 seconds for debug
// 10 minutes for release
const defaultAutolockTimer = (kDebugMode) ? 60 : 10 * 60;

int autolockLeft = defaultAutolockTimer;

void resetAutolock() {
  autolockLeft = defaultAutolockTimer;
}

Timer globalAutolockTimer = Timer.periodic(Duration.zero, (_) {});

bool isScheduledAutolockTimer = false;
void scheduleAutolockTimer() {
  if (isScheduledAutolockTimer) return;
  isScheduledAutolockTimer = true;

  if (kDebugMode) print("scheduleAutolockTimer");
  globalAutolockTimer =
      Timer.periodic(const Duration(seconds: 5), (timer) async {
    if ((await WalletChannel().isSynchronized()) == false) {
      print("Wallet is not synchronized, delaying lock timer.");
      return;
    }
    autolockLeft -= 5;
    if (autolockLeft > 0) {
      return;
    }
    isScheduledAutolockTimer = false;
    timer.cancel();
    print("Locking!");
    if (navigatorKey.currentState == null) {
      print("NavigatorKey is null");
      return;
    }
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) {
          if (isViewOnly) {
            // We are doing a 'fake' lock, since
            // WalletLock is actually locking the
            // wallet (turning background-sync on)
            // and we don't want it for viewonly.
            return const LockedWallet();
          }
          return const WalletLock();
        },
      ),
    );
  });
}
