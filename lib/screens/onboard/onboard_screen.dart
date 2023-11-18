import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/screens/onboard/onboard_state.dart';
import 'package:anon_wallet/screens/onboard/polyseed_widget.dart';
import 'package:anon_wallet/screens/onboard/remote_node_setup.dart';
import 'package:anon_wallet/screens/onboard/wallet_passphrase.dart';
import 'package:anon_wallet/screens/set_pin_screen.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardScreen extends ConsumerStatefulWidget {
  const OnboardScreen({super.key});

  @override
  ConsumerState<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends ConsumerState<OnboardScreen> {
  PageController pageController = PageController();
  int currentPage = 0;
  String page = "NODE CONNECTION";
  String seedPassPhrase = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      pageController.addListener(() {
        if (pageController.page != null) {
          ref.read(navigatorState.notifier).state =
              pageController.page!.toInt();
        }
        setState(() {
          if (pageController.page == 0) {
            page = "NODE CONNECTION";
          }
          if (pageController.page == 1) {
            page = "ENTER PASSPHRASE FOR MNEMONIC";
          }
          if (pageController.page == 2) {
            page = "POLYSEED MNEMONIC";
          }
        });
      });
    });
  }

  @override
  void dispose() {
    try {
      ref.read(remoteUserName.notifier).state = "";
      ref.read(remotePassword.notifier).state = "";
      ref.read(remoteHost.notifier).state = "";
      ref.read(navigatorState.notifier).state = 0;
      ref.read(walletSeedPhraseProvider.notifier).state = "";
      ref.read(walletLockPin.notifier).state = "";
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Wallet? wallet = ref.watch(newWalletProvider);
    return WillPopScope(
      onWillPop: () async {
        if (pageController.page == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (c) {
              return const WalletHome();
            }),
            (route) => false,
          );
        }
        if (pageController.page == 0) {
          return true;
        } else {
          pageController.previousPage(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutSine);
          return false;
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Center(
              child: Center(
                child: Hero(
                  tag: "anon_logo",
                  child: SafeArea(
                    child: SizedBox(
                      width: 180,
                      child: Image.asset("assets/anon_logo.png"),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                children: [
                  const RemoteNodeWidget(),
                  WalletPassphraseWidget(
                    heroEnabled: false,
                    onPassSeedPhraseAdded: (value) {
                      ref.read(walletSeedPhraseProvider.state).state = value;
                    },
                  ),
                  Scaffold(
                    body: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Center(
                            child: SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                ))),
                        Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: const Text(
                                "Creating your wallet please wait..."))
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 26),
                    child: PolySeedWidget(
                      heroEnabled: false,
                      seedWords: wallet == null ? [] : wallet.seed,
                    ),
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, c) {
                var value = ref.watch(nextButtonValidation);
                var page = ref.watch(navigatorState);
                var rHost = ref.watch(remoteHost);
                Node? connection = ref.watch(nodeConnectionState).value;
                String nextButton = "Connect";
                if (page == 0) {
                  if (rHost.isEmpty) {
                    nextButton = "Skip";
                  } else if (connection != null && connection.isConnected()) {
                    nextButton = "Next";
                  } else {
                    nextButton = "Connect";
                  }
                }
                if (page == 1) {
                  nextButton = "Next";
                }
                if (page == 2) {
                  nextButton = "";
                  return Container();
                }
                if (page == 3) {
                  nextButton = "Finish";
                }
                return Container(
                  alignment: Alignment.bottomCenter,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(width: 1.0, color: Colors.white),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  width: 12, color: Colors.white),
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 6)),
                      onPressed: () async {
                        if (rHost.isEmpty && page == 0) {
                          showConfirmColdAlert();
                        } else if (value) {
                          onNext(context);
                        }
                      },
                      child: Text(nextButton),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showConfirmColdAlert() {
    FocusNode focusNode = FocusNode();
    showDialog(
        context: context,
        barrierColor: barrierColor,
        barrierDismissible: false,
        builder: (context) {
          return HookBuilder(
            builder: (context) {
              useEffect(() {
                focusNode.requestFocus();
                return null;
              }, []);
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width / 1.3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Creating offline wallet.\n\nUse NERO to send airgapped transactions from this device.",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        onNext(context, coldMode: true);
                      },
                      child: const Text("Confirm"))
                ],
              );
            },
          );
        });
  }

  onNext(BuildContext context, {bool coldMode = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    Node? connectionState = ref.read(nodeConnectionState).value;
    if (coldMode ||
        (pageController.page == 0 &&
            connectionState != null &&
            connectionState.isConnected())) {
      pageController.nextPage(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutSine);
      return;
    }
    if (pageController.page == 0 && ref.read(remoteHost).trim().isNotEmpty) {
      try {
        await ref.read(nodeConnectionProvider.notifier).connect();
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text("${e.message}"),
            actions: [
              TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  },
                  child: const Text("Close"))
            ],
          ),
        );
      }
      return;
    }

    if (pageController.page == 1) {
      await Future.delayed(const Duration(milliseconds: 200));
      String? pin = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return const SetPinScreen();
          },
          fullscreenDialog: true));
      if (pin != null) {
        pageController.nextPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutSine);
        await ref.read(newWalletProvider.notifier).createWallet(pin);
        pageController.nextPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutSine);
        return;
      }
    } else {
      if (pageController.page == 3) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) {
            return const WalletHome();
          }),
          (route) => false,
        );
        return;
      }
    }
  }
}
