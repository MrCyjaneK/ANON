import 'dart:async';

import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/receive_screen.dart';
import 'package:anon_wallet/screens/home/settings/settings_main.dart';
import 'package:anon_wallet/screens/home/spend/airgap_export_screen.dart';
import 'package:anon_wallet/screens/home/spend/spend_form_main.dart';
import 'package:anon_wallet/screens/home/transactions/transactions_list.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/widgets/bottom_bar.dart';
import 'package:anon_wallet/widgets/qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sembast/sembast.dart';

class WalletHome extends ConsumerStatefulWidget {
  final int startScreen;
  const WalletHome({
    this.startScreen = 0,
    super.key,
  });

  @override
  ConsumerState<WalletHome> createState() => WalletHomeState();
}

final lockPageViewScroll = StateProvider<bool>((ref) => false);

class WalletHomeState extends ConsumerState<WalletHome> {
  late int _currentView = widget.startScreen;
  late final PageController _pageController =
      PageController(initialPage: _currentView);
  GlobalKey scaffoldState = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _bottomSheetController;
  List<String>? outputs;
  num maxAmount = 0;
  @override
  void initState() {
    WalletChannel().getUtxos().then((value) {
      final tmpval = [];
      value.forEach((key, value) {
        if (!value["spent"]) {
          tmpval.add(value);
        }
      });
      List<String> outs = [];
      num maxAmt = 0;
      for (var output in tmpval) {
        if (output["is_selected"] == true) {
          outs.add(output["keyImage"]);
          maxAmt += output["amount"];
        }
      }
      setState(() {
        outputs = outs;
        maxAmount = maxAmt;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (outputs == null) {
      return const Scaffold(
        body: LinearProgressIndicator(),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        if (_bottomSheetController != null) {
          _bottomSheetController!.close();
          _bottomSheetController = null;
          return false;
        }
        if (_pageController.page == 0) {
          return await showDialog(
              context: context,
              barrierColor: barrierColor,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  content: const Text("Do you want to exit the app ?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text("No")),
                    TextButton(
                        onPressed: () async {
                          await WalletChannel().store();
                          if (!mounted) return;
                          Navigator.of(context).pop(true);
                          SystemNavigator.pop(animated: true);
                        },
                        child: const Text("Yes")),
                  ],
                );
              });
        } else {
          _pageController.jumpToPage(0);
        }
        return false;
      },
      child: Scaffold(
        key: scaffoldState,
        body: Consumer(builder: (context, ref, child) {
          bool lock = ref.watch(lockPageViewScroll);
          return PageView(
            controller: _pageController,
            physics: lock
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            children: [
              Builder(
                builder: (context) {
                  return TransactionsList(
                    onScanClick: (newContext) async {
                      showModalScanner(newContext);
                    },
                  );
                },
              ),
              ReceiveWidget(() {
                _pageController.jumpToPage(0);
              }),
              Scaffold(
                appBar: AppBar(
                  leading: BackButton(
                    onPressed: () {
                      _pageController.jumpToPage(0);
                    },
                  ),
                ),
                body: AnonSpendForm(
                    outputs: outputs ?? [],
                    maxAmount: maxAmount,
                    goBack: () {
                      _pageController.jumpToPage(0);
                    }),
              ),
              Scaffold(
                appBar: AppBar(
                  title: const Text("Settings"),
                  leading: BackButton(
                    onPressed: () {
                      _pageController.jumpTo(0);
                    },
                  ),
                ),
                body: const SettingsScreen(),
              ),
            ],
            onPageChanged: (index) {
              if (_bottomSheetController != null) {
                _bottomSheetController!.close();
                _bottomSheetController = null;
              }
              setState(() => _currentView = index);
            },
          );
        }),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            ref.listen<String?>(nodeErrorState,
                (String? previousCount, String? newValue) {
              if (newValue != null && scaffoldState.currentContext != null) {
                // NOTE: Node not connected, old banner.
                // ScaffoldMessenger.of(scaffoldState.currentContext!)
                //     .showMaterialBanner(
                //         MaterialBanner(content: Text(newValue), actions: [
                //   TextButton(
                //       onPressed: () {
                //         ScaffoldMessenger.of(context)
                //             .hideCurrentMaterialBanner();
                //       },
                //       child: const Text("Close"))
                // ]));
              } else {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              }
            });
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: BottomBar(
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedIndex: _currentView,
          onTap: (int index) {
            setState(() => _currentView = index);
            _pageController.jumpToPage(index);
          },
          items: <BottomBarItem>[
            BottomBarItem(
              icon: const Icon(Icons.home),
              title: const Text('Home'),
              activeColor: Theme.of(context).primaryColor,
            ),
            BottomBarItem(
              icon: const Icon(Icons.qr_code),
              title: const Text('Receive'),
              activeColor: Theme.of(context).primaryColor,
            ),
            BottomBarItem(
              icon: const Icon(Icons.send_outlined),
              title: const Text('Send'),
              activeColor: Theme.of(context).primaryColor,
            ),
            BottomBarItem(
              icon: const Icon(Icons.settings),
              title: const Text('Settings'),
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void showModalScanner(BuildContext newContext) {
    final messenger = ScaffoldMessenger.of(newContext);
    final theme = Theme.of(context);
    PersistentBottomSheetController? bottomSheetController;

    QRResult? result;
    bottomSheetController = showQRBottomSheet(
      newContext,
      onScanCallback: (value) {
        result = value;
      },
    );
    final navigator = Navigator.of(newContext);
    bottomSheetController.closed.then((value) async {
      await Future.delayed(const Duration(milliseconds: 200));
      print(result?.type);
      if (result != null && result!.type == QRResultType.text) {
        _pageController.animateToPage(2,
            duration: const Duration(milliseconds: 1), curve: Curves.linear);
        return;
      } else {
        if (result != null && result!.type == QRResultType.UR) {
          if (result!.urResult.isNotEmpty) {}
          switch (result!.urType) {
            case UrType.xmrOutPut:
              String message = "";
              if (result!.urResult.isNotEmpty) {
                message = "";
              }
              if (result!.urError != null) {
                message = result!.urError!;
              }
              if (message != "") {
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.grey[900],
                    content: Text(
                      message,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.primaryColor),
                    ),
                  ),
                );
              }
              Future.delayed(Duration.zero)
                  .then((_) => exportKeyImages(context));
              break;
            case UrType.xmrKeyImage:
              String message = "";
              if (result!.urResult.isNotEmpty) {
                message = result!.urResult;
              }
              if (result!.urError != null) {
                message = result!.urError!;
              }
              messenger.showSnackBar(SnackBar(
                  backgroundColor: Colors.grey[900],
                  content: Text(
                    message,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.primaryColor),
                  )));
              break;
            case UrType.xmrTxUnsigned:
              navigator.push(MaterialPageRoute(
                builder: (context) {
                  return AnonSpendForm(
                      scannedType: UrType.xmrTxUnsigned,
                      outputs: outputs ?? [],
                      maxAmount: maxAmount,
                      goBack: () {
                        _pageController.jumpTo(0);
                      });
                },
              ));
              break;
            case UrType.xmrTxSigned:
              navigator.push(MaterialPageRoute(
                builder: (context) {
                  return AnonSpendForm(
                      scannedType: UrType.xmrTxSigned,
                      outputs: outputs ?? [],
                      maxAmount: maxAmount,
                      goBack: () {
                        _pageController.jumpTo(0);
                      });
                },
              ));
              break;
            case null:
              {}
          }
        }
      }
    });
  }

  void exportKeyImages(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return ExportQRScreen(
          title: "KEY IMAGES",
          buttonText: "SCAN UNSIGNED TX",
          exportType: UrType.xmrKeyImage,
          counterScanCalled: (String data, BuildContext newContext) async {
            // await BackUpRestoreChannel().exportFile(data);
            Future.delayed(Duration.zero).then(
              (value) {
                showModalScanner(newContext);
              },
            );
          },
          onScanClick: (newContext) async {
            showModalScanner(newContext);
          },
        );
      },
    ));
  }
}

navigateToHome(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.settings.name == "/");
}
