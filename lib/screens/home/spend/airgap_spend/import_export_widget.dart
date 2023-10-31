import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/spend/airgap_spend/airgap_qr.dart';
import 'package:anon_wallet/screens/home/spend/airgap_spend/airgap_state.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PayloadImportExportWidget extends ConsumerStatefulWidget {
  final UrType urType;
  final String importTitle;
  final String buttonText;
  final Function onMainButtonPress;

  const PayloadImportExportWidget({
    super.key,
    required this.urType,
    required this.importTitle,
    required this.buttonText,
    required this.onMainButtonPress,
  });

  @override
  ConsumerState<PayloadImportExportWidget> createState() =>
      _QRImportExportState();
}

final exportFilePathProvider = FutureProvider.family<String, UrType>(
  (ref, type) => SpendMethodChannel().getFilePath(type),
);

class _QRImportExportState extends ConsumerState<PayloadImportExportWidget> {
  bool showScanner = false;
  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (pageController.page != null) {
          if (pageController.page! >= 1) {
            pageController.animateToPage(0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInQuad);
            return Future.value(false);
          }
          return Future.value(true);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              if (pageController.page != null) {
                if (pageController.page! >= 1) {
                  pageController.animateToPage(0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeIn);
                }
              }
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        body: QRWidget(),
      ),
    );
  }

  Widget QRWidget() {
    final path = ref.watch(exportFilePathProvider(widget.urType));
    return path.when(
      data: (data) {
        return Scaffold(
          primary: false,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AirGapQR(
                  showPlaceHolder: false,
                  urGenerateRequest: URGenerateRequest(
                    fpath: data,
                    type: widget.urType,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                      label: const Text("Export As File")),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: OutlinedButton(
                style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                  padding: MaterialStateProperty.resolveWith((states) {
                    return const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8);
                  }),
                ),
                onPressed: () async {
                  print('import_export_widget.dart');
//                  widget.onMainButtonPress();
                  await BackUpRestoreChannel().exportFile(data);
                  context
                      .findRootAncestorStateOfType<WalletHomeState>()
                      ?.showModalScanner(context);
                },
                child: Text(widget.buttonText)),
          ),
        );
      },
      error: (error, stackTrace) => const Text("Error "),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
