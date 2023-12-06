import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/spend/airgap_export_screen.dart';
import 'package:anon_wallet/screens/home/spend/spend_review.dart';
import 'package:anon_wallet/screens/home/spend/spend_state.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/keyboard_visibility_detector.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AnonSpendForm extends ConsumerStatefulWidget {
  final UrType? scannedType;

  const AnonSpendForm({
    super.key,
    this.scannedType,
    required this.outputs,
    required this.maxAmount,
    this.addAppBar = false,
    required this.goBack,
  });

  final void Function() goBack;
  final List<String> outputs;
  final num maxAmount;
  final bool addAppBar;

  @override
  ConsumerState<AnonSpendForm> createState() => _SpendFormState();
}

class _SpendFormState extends ConsumerState<AnonSpendForm> {
  TextEditingController addressEditingController = TextEditingController();
  TextEditingController amountEditingController = TextEditingController();
  TextEditingController noteEditingController = TextEditingController();

  bool isKeyboardVisible = false;

  bool sweepAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      addressEditingController.text = ref.read(addressStateProvider);
      amountEditingController.text = ref.read(amountStateProvider);
      noteEditingController.text = ref.read(notesStateProvider);
      _init();
    });
  }

  showErrorDialog(Exception exception) {
    print("exception ${exception.toString()}");
    String message = "$exception";
    if (exception is PlatformException) {
      message = exception.message ?? "Unknown error";
    }
    if (message.isEmpty) {
      message = "Unknown error";
    }
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).canvasColor,
          content: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
                onPressed: () async {
                  navigateToHome(context);
                },
                child: const Text("OK")),
          ],
        );
      },
    );
  }

  int balance = 0;

  Future _init() async {
    // final context = context;
    final newBal = await WalletChannel().viewOnlyBalance();
    setState(() {
      balance = newBal;
    });
    final navigator = Navigator.of(context);
    if (widget.scannedType != null) {
      if (widget.scannedType == UrType.xmrTxUnsigned) {
        navigator.pushNamed("/loading-tx");
        await ref.read(transactionStateProvider.notifier).loadUnSignedTx();
        navigator.push(MaterialPageRoute(
          builder: (context) => AnonSpendReview(
            onActionClicked: signAndShowTx,
          ),
        ));
      }
      if (widget.scannedType == UrType.xmrTxSigned) {
        Widget alert = AlertDialog(
          backgroundColor: Theme.of(context).canvasColor,
          title: const Text("Broadcast Transaction"),
          content: const Text("Do you want to broadcast this transaction?"),
          actions: [
            TextButton(
                onPressed: () async {
                  navigateToHome(context);
                },
                child: const Text("NO")),
            TextButton(
                onPressed: () async {
                  navigator.pushNamed("/loading-broadcast-tx");
                  try {
                    await SpendMethodChannel().broadcastSigned();
                    navigator.pushNamed("/tx-success");
                  } on Exception catch (e) {
                    showErrorDialog(e);
                    print(e);
                  }
                },
                child: const Text("Yes")),
          ],
        );
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (context) => alert,
        );
      }
    }
  }

  signAndShowTx() async {
    final navigator = Navigator.of(context);

    //Air-gap wallet
    if (!isViewOnly && isAirgapEnabled) {
      navigator.pushNamed("/loading-tx-signing");
      await ref.read(transactionStateProvider.notifier).signUnSigned();
      navigator.push(MaterialPageRoute(
        builder: (context) {
          return ExportQRScreen(
            title: "SIGNED TX",
            isInTxComposeMode: true,
            exportType: UrType.xmrTxSigned,
            buttonText: "FINISH",
            counterScanCalled: (_, newContext) {
              navigateToHome(newContext);
              Future.delayed(Duration.zero).then((_) => widget.goBack());
            },
            onScanClick: (_) =>
                print("spend_from_main.dart: onScanClick is not supported"),
          );
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(notesStateProvider, (previous, next) {
      if (noteEditingController.text != next) {
        noteEditingController.text = next;
      }
    });
    ref.listen<String>(addressStateProvider, (previous, next) {
      if (addressEditingController.text != next) {
        addressEditingController.text = next;
      }
    });
    ref.listen<String>(amountStateProvider, (previous, next) {
      if (amountEditingController.text != next) {
        amountEditingController.text = next;
      }
    });

    OutlineInputBorder enabledBorder = OutlineInputBorder(
        borderSide: BorderSide(width: 1, color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(12));

    OutlineInputBorder unFocusedBorder = OutlineInputBorder(
        borderSide: const BorderSide(width: 1, color: Colors.white),
        borderRadius: BorderRadius.circular(12));
    SpendValidationNotifier validationNotifier = ref.watch(validationProvider);

    bool? addressValid = validationNotifier.validAddress;
    bool? validAmount = validationNotifier.validAmount;

    return KeyboardVisibilityListener(
      listener: (visible) {
        setState(() {
          isKeyboardVisible = visible;
        });
      },
      child: Scaffold(
        appBar: widget.addAppBar ? AppBar() : null,
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          ListTile(
                            title: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "ADDRESS",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary),
                              ),
                            ),
                            subtitle: TextFormField(
                              autofocus: false,
                              textAlign: TextAlign.start,
                              controller: addressEditingController,
                              keyboardType: TextInputType.text,
                              maxLines: 3,
                              minLines: 1,
                              onChanged: (value) {
                                ref.read(addressStateProvider.state).state =
                                    value;
                              },
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                errorText: addressValid == false
                                    ? "Invalid address"
                                    : null,
                                border: unFocusedBorder,
                                enabledBorder: unFocusedBorder,
                                focusedBorder: enabledBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                fillColor: const Color(0xff1E1E1E),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          ListTile(
                            title: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "AMOUNT",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary),
                              ),
                            ),
                            subtitle: TextFormField(
                              // enabled: !sweepAll,
                              controller: amountEditingController,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                num amount =
                                    ref.watch(walletAvailableBalanceProvider);
                                if (widget.maxAmount != 0) {
                                  amount = widget.maxAmount;
                                }
                                num? amtInput = num.tryParse(value);
                                if (amtInput == null) {
                                  setState(() {
                                    sweepAll = false;
                                  });
                                } else {
                                  amtInput = amtInput * 1e12;
                                  setState(() {
                                    sweepAll = amount == amtInput;
                                  });
                                }
                                ref.read(amountStateProvider.state).state =
                                    value;
                              },
                              autofocus: false,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                errorText: validAmount == false
                                    ? "Invalid Amount"
                                    : null,
                                //suffixText: "XMR",
                                border: unFocusedBorder,
                                enabledBorder: unFocusedBorder,
                                focusedBorder: enabledBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                fillColor: const Color(0xff1E1E1E),
                              ),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          ListTile(
                            title: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "NOTES",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary),
                              ),
                            ),
                            subtitle: TextFormField(
                              textAlign: TextAlign.start,
                              onChanged: (value) {
                                ref.read(notesStateProvider.state).state =
                                    value;
                              },
                              autofocus: false,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                border: unFocusedBorder,
                                enabledBorder: unFocusedBorder,
                                focusedBorder: enabledBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 8),
                                fillColor: const Color(0xff1E1E1E),
                              ),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      if (isViewOnly && kDebugMode)
                        Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 80,
                          child: Consumer(
                            builder: (context, ref, c) {
                              num amount =
                                  ref.watch(walletAvailableBalanceProvider);
                              if (widget.maxAmount != 0) {
                                amount = widget.maxAmount;
                              }
                              return Text(
                                sweepAll
                                    ? ""
                                    : "Quick Spend: ${formatMonero(balance)}",
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: (() {
                          num amount =
                              ref.watch(walletAvailableBalanceProvider);
                          if (widget.maxAmount != 0) {
                            amount = widget.maxAmount;
                          }
                          setState(() {
                            sweepAll = !sweepAll;
                            amountEditingController.text =
                                sweepAll ? formatMonero(amount) : '';
                          });
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          height: 80,
                          child: Consumer(
                            builder: (context, ref, c) {
                              num amount =
                                  ref.watch(walletAvailableBalanceProvider);
                              if (widget.maxAmount != 0) {
                                amount = widget.maxAmount;
                              }
                              return Text(
                                sweepAll
                                    ? "Sweeping ${formatMonero(amount)} (minus fee)"
                                    : "Available Balance : ${formatMonero(amount)}",
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: Semantics(
                            label: 'Scan QR code',
                            child: IconButton(
                              iconSize: 48,
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onPressed: () {
                                context
                                    .findRootAncestorStateOfType<
                                        WalletHomeState>()
                                    ?.showModalScanner(context);
                              },
                              icon: const Icon(Icons.crop_free_sharp),
                            )),
                      ),
                    ],
                  ),
                ))
          ],
        ),
        bottomNavigationBar: isKeyboardVisible
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24)
                    .add(const EdgeInsets.only(bottom: 12)),
                child: Builder(builder: (context) {
                  return Opacity(
                    opacity: View.of(context).viewInsets.bottom > 0 ? 0 : 1,
                    child: Hero(
                      tag: "main_button",
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  width: 1.0, color: Colors.white),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                      width: 12, color: Colors.white),
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 6)),
                          onPressed: () => onMainActionPressed(context),
                          child: const Text("Continue")),
                    ),
                  );
                }),
              ),
      ),
    );
  }

  onImportKeyPressed(BuildContext newContext) async {
    final value = await scanURPayload(
        UrType.xmrKeyImage, newContext, "IMPORT KEY IMAGES");
    if (value != null) {
      if (value.urType == UrType.xmrKeyImage &&
          value.urResult.toLowerCase() == "imported") {
        String amountStr = ref.read(amountStateProvider);
        String address = ref.read(addressStateProvider);
        String notes = ref.read(notesStateProvider);
        if (isViewOnly) {
          try {
            ref.read(transactionStateProvider.notifier).composeAndSave(
                amountStr, address, sweepAll, notes, widget.outputs);
            showSpendReview(newContext);
          } catch (e) {
            print(e);
          }
        } else {
          ref.read(transactionStateProvider.notifier).createPreview(
              amountStr, address, sweepAll, notes, widget.outputs);
          Navigator.of(newContext).push(MaterialPageRoute(
            builder: (newContext) => const AnonSpendReview(),
          ));
        }
      }
    }
  }

  void showSpendReview(BuildContext newContext) {
    Navigator.of(newContext).push(MaterialPageRoute(
      builder: (newContext) => AnonSpendReview(
        onActionClicked: () => scanSignedTx(newContext),
      ),
    ));
  }

  void scanSignedTx(BuildContext newContext) {
    Navigator.of(newContext).push(MaterialPageRoute(
      builder: (newContext) => ExportQRScreen(
        exportType: UrType.xmrTxUnsigned,
        buttonText: "SCAN SIGNED TX",
        isInTxComposeMode: true,
        counterScanCalled: (_, newContext) {
          onScanSignedTxPressed(newContext);
        },
        title: "UNSIGNED TX",
        onScanClick: (_) =>
            print("spend_from_main.dart: onScanClick is not supported2"),
      ),
    ));
  }

  onScanSignedTxPressed(BuildContext c) async {
    final navigator = Navigator.of(c);
    final value =
        await scanURPayload(UrType.xmrTxSigned, c, "IMPORT SIGNED TX");
    if (value != null) {
      if (value.urType == UrType.xmrTxSigned && value.urError == null) {
        if (isViewOnly) {
          try {
            Widget alert = AlertDialog(
              backgroundColor: Theme.of(c).canvasColor,
              title: const Text("Broadcast Transaction"),
              content: const Text("Do you want to broadcast this transaction?"),
              actions: [
                TextButton(
                    onPressed: () async {
                      navigateToHome(c);
                    },
                    child: const Text("NO")),
                TextButton(
                    onPressed: () async {
                      navigator.pushNamed("/loading-broadcast-tx");
                      try {
                        await SpendMethodChannel().broadcastSigned();
                        navigator.pushNamed("/tx-success");
                      } on PlatformException catch (e) {
                        print(e);
                        showErrorDialog(e);
                      }
                    },
                    child: const Text("Yes")),
              ],
            );
            showDialog(
              context: c,
              barrierDismissible: false,
              useRootNavigator: true,
              builder: (context) => alert,
            );
          } catch (e) {
            if (kDebugMode) {
              print(e);
            }
          }
        } else {}
      }
    }
  }

  onMainActionPressed(BuildContext context) async {
    print("onMainActionPressed:");
    FocusScope.of(context).unfocus();
    final navigatorState = Navigator.of(context, rootNavigator: false);
    String amountStr = ref.read(amountStateProvider);
    String address = ref.read(addressStateProvider);
    SpendValidationNotifier validationNotifier = ref.read(validationProvider);
    bool valid =
        await validationNotifier.validate(amountStr, address, sweepAll);
    if (valid) {
      //if view only then export outputs and start working unsigned tx
      if (isViewOnly) {
        try {
          bool needKeyImages = false;
          print("sweepAll:${await WalletChannel().hasUnknownKeyImages()}");
          if (sweepAll) {
            needKeyImages = await WalletChannel().hasUnknownKeyImages();
          } else {
            print(amountStr);
            print("numParse: ${num.tryParse(amountStr)}");
            print(
                "await WalletChannel().viewOnlyBalance();${await WalletChannel().viewOnlyBalance()}");
            needKeyImages = ((num.parse(amountStr) + 0.001) * 1e12) >
                await WalletChannel().viewOnlyBalance();
            //     // 0.001 XMR to account for tx fee
            //     return ((amount + WalletManager::amountFromDouble(0.001)) > m_wallet->viewOnlyBalance(m_wallet->currentSubaddressAccount()));
          }
          if (needKeyImages) {
            await WalletChannel().exportOutputs(false);
            navigatorState.push(MaterialPageRoute(
              builder: (context) {
                return ExportQRScreen(
                  title: "OUTPUTS",
                  isInTxComposeMode: true,
                  exportType: UrType.xmrOutPut,
                  buttonText: "SCAN KEY IMAGES",
                  counterScanCalled: (_, newContext) async {
                    await onImportKeyPressed(newContext);
                  },
                  onScanClick: (_) => print(
                      "spend_from_main.dart: onScanClick is not supported3"),
                );
              },
            ));
          } else {
            String amountStr = ref.read(amountStateProvider);
            String address = ref.read(addressStateProvider);
            String notes = ref.read(notesStateProvider);
            ref.read(transactionStateProvider.notifier).composeAndSave(
                amountStr, address, sweepAll, notes, widget.outputs);
            showSpendReview(context);
          }
        } catch (e) {
          print(e);
        }
      } else {
        if (isAirgapEnabled) {
          //create signed tx and show qr
          try {
            navigatorState.pushNamed("/loading-tx-construct");
            await ref.read(transactionStateProvider.notifier).composeAndSave(
                amountStr, address, sweepAll, "", widget.outputs);
            navigatorState.push(MaterialPageRoute(
              builder: (context) => ExportQRScreen(
                exportType: UrType.xmrTxSigned,
                buttonText: "FINISH",
                isInTxComposeMode: true,
                counterScanCalled: (_, newContext) async {
                  await navigateToHome(newContext);
                  Future.delayed(Duration.zero).then((_) => widget.goBack());
                },
                onScanClick: (_) => print(
                    "spend_from_main.dart: onScanClick is not supported4"),
                title: "SIGNED TX",
              ),
            ));
          } catch (e) {
            print(e);
          }
        } else {
          //Normal tx
          String amountStr = ref.read(amountStateProvider);
          String address = ref.read(addressStateProvider);
          String notes = ref.read(notesStateProvider);
          ref.read(transactionStateProvider.notifier).createPreview(
              amountStr, address, sweepAll, notes, widget.outputs);
          navigatorState.push(MaterialPageRoute(
            builder: (context) {
              return AnonSpendReview(
                onActionClicked: () async {
                  navigatorState.pushNamed("/loading-broadcast-tx");
                  await ref.read(transactionStateProvider.notifier).broadcast(
                      amountStr, address, sweepAll, notes, widget.outputs);
                  ref.read(amountStateProvider.notifier).state = "";
                  ref.read(addressStateProvider.notifier).state = "";
                  ref.read(notesStateProvider.notifier).state = "";
                  navigatorState.pushNamed("/tx-success");
                },
              );
            },
          ));
        }
      }
    }
  }
}
