import 'dart:async';

import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/spend/airgap_spend/airgap_qr.dart';
import 'package:anon_wallet/screens/home/spend/airgap_spend/airgap_state.dart';
import 'package:anon_wallet/screens/home/spend/airgap_spend/import_export_widget.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/widgets/qr_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ExportQRScreen extends ConsumerStatefulWidget {
  // use images and outs as the type
  final UrType exportType;
  final String title;
  final String buttonText;
  final bool isInTxComposeMode;

  final Function counterScanCalled;

  const ExportQRScreen(
      {super.key,
      required this.exportType,
      required this.counterScanCalled,
      required this.title,
      this.isInTxComposeMode = false,
      required this.buttonText});

  @override
  ConsumerState<ExportQRScreen> createState() => _ImportFromQRScreenState();
}

class _ImportFromQRScreenState extends ConsumerState<ExportQRScreen> {
  @override
  Widget build(BuildContext context) {
    var exportProvider = exportFilePathProvider(widget.exportType);

    //Use specific provider xmrKeyImage and xmrOuts
    if (widget.exportType == UrType.xmrKeyImage) {
      exportProvider = exportWalletKeyImagesProvider;
    } else if (widget.exportType == UrType.xmrOutPut) {
      exportProvider = exportWalletOutProvider;
    }

    final asyncQRData = ref.watch(exportProvider);

    return WillPopScope(
      onWillPop: () async {
        if (widget.isInTxComposeMode) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                content: const Text("Do you want to cancel ?"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        return;
                      },
                      child: const Text("No")),
                  TextButton(
                      onPressed: () {
                        navigateToHome(context);
                        return;
                      },
                      child: const Text("Yes")),
                ],
              );
            },
          );
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () async {
              if (widget.isInTxComposeMode) {
                return await showDialog(
                    context: context,
                    barrierColor: barrierColor,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        content: const Text("Do you want to cancel ?"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text("No")),
                          TextButton(
                              onPressed: () {
                                navigateToHome(context);
                                return;
                              },
                              child: const Text("Yes")),
                        ],
                      );
                    });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: asyncQRData.when(
          data: (data) {
            return Scaffold(
              primary: false,
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color: Theme.of(context).primaryColor,fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: AirGapQR(
                        showPlaceHolder: false,
                        urGenerateRequest: URGenerateRequest(
                            type: widget.exportType, fpath: data),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextButton.icon(
                          onPressed: () async {
                            try {
                              BackUpRestoreChannel().exportFile(data);
                            } catch (e) {
                              if (kDebugMode) {
                                print(e);
                              }
                            }
                          },
                          icon: const Icon(Icons.save_alt),
                          label: const Text("Export as File")),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Padding(
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
                          onPressed: () async {
                            widget.counterScanCalled.call();
                          },
                          child: Text(widget.buttonText)),
                    ),
                  );
                }),
              ),
            );
          },
          loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          error: (error, stackTrace) {
            var errorMessage = "${error}";
            try {
              var errorMessage =
                  (error as PlatformException).message ?? "Unable to process";
            } catch (e) {}
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(errorMessage,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.red)),
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<QRResult?> scanURPayload(
    UrType type, BuildContext context, String importTitle) async {
  Completer<QRResult> completer = Completer();
  pickFromFile(ValueNotifier<bool> progress) async {
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: importTitle,
      allowMultiple: false,
    );
    progress.value = true;
    if (result != null && result.files.isNotEmpty) {
      try {
        await WalletChannel().setTrustedDaemon(true);
        final resp =
            await WalletChannel().importFromFile(type, result.files[0].path!);
        progress.value = false;
        if (resp) {
          if (!completer.isCompleted) {
            completer.complete(QRResult(
                urType: type,
                type: QRResultType.UR,
                urResult: resp.toString()));
            navigator.pop();
          }
        } else {
          navigator.pop();
          scaffold.showSnackBar(const SnackBar(
              content: Text(
            "Unable to import",
          )));
        }
      } catch (e) {
        navigator.pop();
        scaffold.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) {
      return HookConsumer(
        builder: (context, ref, child) {
          ValueNotifier<bool> progress = useState(false);
          return FractionallySizedBox(
            heightFactor: 1,
            child: Stack(
              children: [
                QRScannerView(
                  onScanCallback: (value) async {
                    if (value.urType != null && value.urResult.isNotEmpty) {
                      if (!completer.isCompleted) {
                        completer.complete(value);
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                Align(
                  alignment: Alignment.center.add(const Alignment(0, -.64)),
                  child: Text(importTitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 320),
                  opacity: progress.value ? 1 : 0,
                  child: const Center(
                    child: SizedBox.square(
                        dimension: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                        )),
                  ),
                ),
                Align(
                  alignment: Alignment.center.add(const Alignment(0, .64)),
                  child: OutlinedButton(
                    onPressed: () async {
                      pickFromFile(progress);
                    },
                    child: const Text("Import File"),
                  ),
                )
              ],
            ),
          );
        },
      );
    },
  );
  return completer.future;
}
