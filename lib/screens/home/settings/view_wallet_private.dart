import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:anon_wallet/models/config.dart';
import 'package:anon_wallet/models/wallet.dart';
import 'package:anon_wallet/screens/home/settings/settings_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ViewWalletSeed extends ConsumerStatefulWidget {
  const ViewWalletSeed({Key? key}) : super(key: key);

  @override
  ConsumerState<ViewWalletSeed> createState() => _ViewWalletSeedState();
}

class _ViewWalletSeedState extends ConsumerState<ViewWalletSeed> {
  @override
  Widget build(BuildContext context) {
    Wallet? wallet = ref.watch(viewPrivateWalletProvider);
    TextStyle? titleStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: Theme.of(context).primaryColor);
    final data = {
      "version": 0,
      "primaryAddress": wallet?.address,
      "privateViewKey": wallet?.secretViewKey,
      "restoreHeight": wallet?.restoreHeight
    };
    return WillPopScope(
      onWillPop: () async {
        ref.read(viewPrivateWalletProvider.notifier).clear();
        return true;
      },
      child: Scaffold(
        body: wallet != null
            ? Padding(
                padding: const EdgeInsets.only(
                    top: 14, right: 18, left: 18, bottom: 0),
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      title: Text("Seed",
                          style: Theme.of(context).textTheme.titleLarge),
                      bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(12),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                          )),
                    ),
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text("PRIMARY ADDRESS", style: titleStyle),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SelectableText(wallet.address,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(
                        color: Colors.white54,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text("MNEMONIC", style: titleStyle),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Wrap(
                              children: (wallet.seed).map((e) {
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.white10),
                                  child: Text(e,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(
                        color: Colors.white54,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text("VIEW-KEY", style: titleStyle),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SelectableText(wallet.secretViewKey,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(
                        color: Colors.white54,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text("SPEND-KEY", style: titleStyle),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SelectableText(wallet.spendKey,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(
                        color: Colors.white54,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text("RESTORE HEIGHT", style: titleStyle),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SelectableText(
                              "${wallet.restoreHeight ?? "N/A"} ",
                              style: Theme.of(context).textTheme.bodyLarge),
                        ),
                      ),
                    ),
                    if (!anonConfigState.isViewOnly)
                      const SliverToBoxAdapter(
                        child: Divider(
                          color: Colors.white54,
                        ),
                      ),
                    if (!anonConfigState.isViewOnly)
                      SliverToBoxAdapter(
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
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.transparent,
                                content: SizedBox(
                                  width: 340,
                                  height: 340,
                                  child: QrImageView(
                                    backgroundColor: Colors.black,
                                    data: json.encode(data),
                                    version: QrVersions.auto,
                                    eyeStyle: const QrEyeStyle(
                                        color: Colors.white,
                                        eyeShape: QrEyeShape.square),
                                    dataModuleStyle: const QrDataModuleStyle(
                                        color: Colors.white,
                                        dataModuleShape:
                                            QrDataModuleShape.square),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text("EXPORT [ИΞR0] KEYS"),
                        ),
                      )
                  ],
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      showPassphraseDialog();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showPassphraseDialog() {
    TextEditingController controller = TextEditingController();
    FocusNode focusNode = FocusNode();
    showDialog(
        context: context,
        barrierColor: barrierColor,
        barrierDismissible: false,
        builder: (context) {
          return HookBuilder(
            builder: (context) {
              const inputBorder = UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent));
              var error = useState<String?>(null);
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
                        "Enter Passphrase",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Padding(padding: EdgeInsets.all(12)),
                      TextField(
                        focusNode: focusNode,
                        controller: controller,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        obscuringCharacter: "*",
                        decoration: InputDecoration(
                            errorText: error.value,
                            fillColor: Colors.grey[900],
                            filled: true,
                            focusedBorder: inputBorder,
                            border: inputBorder,
                            errorBorder: inputBorder),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        ref.read(viewPrivateWalletProvider.notifier).clear();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(viewPrivateWalletProvider.notifier)
                              .getWallet(controller.text);
                          AppHaptics.lightImpact();
                          Navigator.pop(context);
                        } on PlatformException catch (e, s) {
                          debugPrintStack(stackTrace: s);
                          error.value = e.message;
                        } catch (e) {
                          // debugPrintStack(stackTrace: s);
                          error.value = "Error $e";
                        }
                      },
                      child: const Text("Confirm"))
                ],
              );
            },
          );
        });
  }
}

/// Cool widget for sensitive data. I'm leaving it here just in case.
class BluredQrWidget extends StatefulWidget {
  const BluredQrWidget({Key? key, required this.data}) : super(key: key);

  final String data;
  @override
  BluredQrWidgetState createState() => BluredQrWidgetState();
}

Random rnd = Random();
const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

class BluredQrWidgetState extends State<BluredQrWidget> {
  bool isQrRevealed = false;
  String randomString = "";

  @override
  void initState() {
    setState(() {
      randomString = String.fromCharCodes(Iterable.generate(widget.data.length,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    });
    _generateString();
    Timer.periodic(const Duration(milliseconds: 222), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _generateString();
    });
    super.initState();
  }

  void _generateString() {
    if (randomString.length != widget.data.length) {
      setState(() {
        randomString = String.fromCharCodes(Iterable.generate(
            widget.data.length,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      });
    } else {
      final spl = randomString.split('');
      spl[rnd.nextInt(spl.length - 1)] = String.fromCharCodes(
          [chars.codeUnitAt(rnd.nextInt(chars.length - 1))]);
      setState(() {
        randomString = spl.join('');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isQrRevealed = !isQrRevealed;
        });
      },
      child: !isQrRevealed
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: QrImageView(
                backgroundColor: Colors.black,
                data: randomString,
                version: QrVersions.auto,
                eyeStyle: const QrEyeStyle(
                    color: Colors.white, eyeShape: QrEyeShape.square),
                dataModuleStyle: const QrDataModuleStyle(
                    color: Colors.white,
                    dataModuleShape: QrDataModuleShape.square),
              ),
            )
          : QrImageView(
              backgroundColor: Colors.black,
              data: widget.data,
              version: QrVersions.auto,
              eyeStyle: const QrEyeStyle(
                  color: Colors.white, eyeShape: QrEyeShape.square),
              dataModuleStyle: const QrDataModuleStyle(
                  color: Colors.white,
                  dataModuleShape: QrDataModuleShape.square),
            ),
    );
  }
}
