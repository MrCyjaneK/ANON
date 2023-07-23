import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/spend/airgap_export_screen.dart';
import 'package:anon_wallet/screens/home/spend/spend_review.dart';
import 'package:anon_wallet/screens/home/spend/spend_state.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/utils/keyboard_visibility_detector.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AnonSpendForm extends ConsumerStatefulWidget {
  final UrType? scannedType;

  const AnonSpendForm({Key? key, this.scannedType}) : super(key: key);

  @override
  ConsumerState<AnonSpendForm> createState() => _SpendFormState();
}

class _SpendFormState extends ConsumerState<AnonSpendForm> {
  TextEditingController addressEditingController = TextEditingController();
  TextEditingController amountEditingController = TextEditingController();
  TextEditingController noteEditingController = TextEditingController();

  bool isKeyboardVisible = false;

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

  Future _init() async {
    final _context = context;
    final navigator = Navigator.of(context);
    if (widget.scannedType != null) {
      if (widget.scannedType == UrType.xmrTxUnsigned) {
        navigator.pushNamed("/loading-tx");
        await ref.read(transactionStateProvider.notifier).loadUnSignedTx();
        navigator.pushReplacement(MaterialPageRoute(
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
          context: _context,
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
      navigator.pushReplacement(MaterialPageRoute(
        builder: (context) {
          return ExportQRScreen(
            title: "SIGN TX",
            isInTxComposeMode: true,
            exportType: UrType.xmrTxSigned,
            buttonText: "IMPORT SIGNED TX",
            counterScanCalled: () {},
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 34, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ADDRESS",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                const Padding(padding: EdgeInsets.all(12)),
                                TextFormField(
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
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 34, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("AMOUNT",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                const Padding(padding: EdgeInsets.all(12)),
                                TextFormField(
                                  controller: amountEditingController,
                                  textAlign: TextAlign.center,
                                  onChanged: (value) {
                                    ref.read(amountStateProvider.state).state =
                                        value;
                                  },
                                  autofocus: false,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    alignLabelWithHint: true,
                                    hintText: "0.0000",
                                    errorText: validAmount == false
                                        ? "Invalid Amount"
                                        : null,
                                    suffixText: "XMR",
                                    border: unFocusedBorder,
                                    enabledBorder: unFocusedBorder,
                                    focusedBorder: enabledBorder,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 8),
                                    fillColor: const Color(0xff1E1E1E),
                                  ),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                    horizontal: 34, vertical: 8)
                                .add(const EdgeInsets.only(bottom: 2)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("NOTES",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                const Padding(padding: EdgeInsets.all(12)),
                                TextFormField(
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 80,
                        child: Consumer(
                          builder: (context, ref, c) {
                            num amount =
                            ref.watch(walletAvailableBalanceProvider);
                            return  Text(
                              "Available Balance  : ${formatMonero(amount, minimumFractions: 8)} XMR",
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: IconButton(
                          iconSize: 48,
                          onPressed: () {
                            context
                                .findRootAncestorStateOfType<WalletHomeState>()
                                ?.showModalScanner(context);
                          },
                          icon: const Icon(Icons.crop_free_sharp),
                        ),
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
                              side:
                              const BorderSide(width: 1.0, color: Colors.white),
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

  onImportKeyPressed(BuildContext context) async {
    final navigator = Navigator.of(context);
    final value =
        await scanURPayload(UrType.xmrKeyImage, context, "IMPORT KEY IMAGES");
    if (value != null) {
      if (value.urType == UrType.xmrKeyImage &&
          value.urResult.toLowerCase() == "imported") {
        String amountStr = ref.read(amountStateProvider);
        String address = ref.read(addressStateProvider);
        String notes = ref.read(notesStateProvider);
        if (isViewOnly) {
          try {
            await ref
                .read(transactionStateProvider.notifier)
                .composeAndSave(amountStr, address, notes);
            navigator.push(MaterialPageRoute(
              builder: (context) => AnonSpendReview(
                onActionClicked: () {
                  navigator.push(MaterialPageRoute(
                    builder: (context) => ExportQRScreen(
                        exportType: UrType.xmrTxUnsigned,
                        buttonText: "SCAN SIGNED TX",
                        isInTxComposeMode: true,
                        counterScanCalled: () => onScanSignedTxPressed(context),
                        title: "UNSIGNED TX"),
                  ));
                },
              ),
            ));
          } catch (e) {
            print(e);
          }
        } else {
          await ref
              .read(transactionStateProvider.notifier)
              .createPreview(amountStr, address, notes);
          navigator.push(MaterialPageRoute(
            builder: (context) => const AnonSpendReview(),
          ));
        }
      }
    }
  }

  onScanSignedTxPressed(BuildContext _c) async {
    final navigator = Navigator.of(context);
    final value =
        await scanURPayload(UrType.xmrTxSigned, context, "IMPORT SIGNED TX");
    if (value != null) {
      if (value.urType == UrType.xmrTxSigned && value.urError == null) {
        if (isViewOnly) {
          try {
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
                      } on PlatformException catch (e) {
                        showErrorDialog(e);
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
    FocusScope.of(context).unfocus();
    final navigatorState = Navigator.of(context, rootNavigator: false);
    String amountStr = ref.read(amountStateProvider);
    String address = ref.read(addressStateProvider);
    SpendValidationNotifier validationNotifier = ref.read(validationProvider);
    bool valid = await validationNotifier.validate(amountStr, address);
    if (valid) {
      //if view only then export outputs and start working unsigned tx
      if (isViewOnly) {
        try {
          await WalletChannel().exportOutputs(true);
          navigatorState.push(MaterialPageRoute(
            builder: (context) {
              return ExportQRScreen(
                title: "OUTPUT",
                isInTxComposeMode: true,
                exportType: UrType.xmrOutPut,
                buttonText: "IMPORT KEY IMAGES",
                counterScanCalled: () {
                  onImportKeyPressed(context);
                },
              );
            },
          ));
        } catch (e) {
          print(e);
        }
      } else {
        if (isAirgapEnabled) {
          //create signed tx and show qr
          try {
            navigatorState.pushNamed("/loading-tx-construct");
            await ref
                .read(transactionStateProvider.notifier)
                .composeAndSave(amountStr, address, "");
            navigatorState.push(MaterialPageRoute(
              builder: (context) => ExportQRScreen(
                exportType: UrType.xmrTxSigned,
                buttonText: "FINISH",
                isInTxComposeMode: true,
                counterScanCalled: () {
                  navigatorState
                      .popUntil((route) => route.settings.name == "/");
                },
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
           ref
              .read(transactionStateProvider.notifier)
              .createPreview(amountStr, address, notes);
          navigatorState.push(MaterialPageRoute(
            builder: (context) {
              return AnonSpendReview(
                onActionClicked: () async {
                  navigatorState.pushNamed("/loading-broadcast-tx");
                  await ref
                      .read(transactionStateProvider.notifier)
                      .broadcast(amountStr, address, notes);
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
