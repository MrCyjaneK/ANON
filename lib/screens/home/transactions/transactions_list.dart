import 'dart:io';

import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/spend_channel.dart';
import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/models/transaction.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:anon_wallet/screens/home/spend/airgap_export_screen.dart';
import 'package:anon_wallet/screens/home/spend/spend_form_main.dart';
import 'package:anon_wallet/screens/home/outputs/outputs_screen.dart';
import 'package:anon_wallet/screens/home/transactions/sticky_progress.dart';
import 'package:anon_wallet/screens/home/transactions/tx_details.dart';
import 'package:anon_wallet/screens/home/transactions/tx_item_widget.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/screens/home/wallet_lock.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class TransactionsList extends StatefulWidget {
  final VoidCallback onScanClick;

  const TransactionsList({Key? key, required this.onScanClick})
      : super(key: key);

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
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
    return RefreshIndicator(
      onRefresh: () async {
        await WalletChannel().refresh();
        return;
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: false,
            centerTitle: false,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            expandedHeight: 180,
            actions: [
              Consumer(
                builder: (context, ref, child) {
                  bool isConnecting = ref.watch(connectingToNodeStateProvider);
                  bool isWalletOpening =
                      ref.watch(walletLoadingProvider) ?? false;
                  bool isLoading = isConnecting || isWalletOpening;
                  return Opacity(
                    opacity: isLoading ? 0.5 : 1,
                    child: IconButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (isLoading) return;
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const WalletLock()));
                              },
                        icon: const Hero(
                          tag: "lock",
                          child: Icon(Icons.lock),
                        )),
                  );
                },
              ),
              IconButton(
                  onPressed: () {
                    widget.onScanClick.call();
                  },
                  icon: const Icon(Icons.crop_free)),
              isViewOnly ? _buildViewOnlyMenu(context) : _buildMenu(context),
            ],
            flexibleSpace: InkWell(
              onLongPress: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OutputsScreen(),
                  ),
                );
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              enableFeedback: false,
              child: FlexibleSpaceBar(
                centerTitle: true,
                collapseMode: CollapseMode.pin,
                background: Container(
                  margin: const EdgeInsets.only(top: 80),
                  alignment: Alignment.center,
                  child: Consumer(
                    builder: (context, ref, c) {
                      var amount = ref.watch(walletBalanceProvider);
                      return Text(
                        formatMonero(amount),
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                ),
              ),
            ),
            title: Wrap(
              verticalDirection: VerticalDirection.up,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                Text(isViewOnly ? "[ИΞR0]" : "[ΛИ0И]"),
              ],
            ),
          ),
          const SyncProgressSliver(),
          Consumer(
            builder: (context, ref, child) {
              List<Transaction> transactions = ref.watch(walletTransactions);
              return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                return _buildTxItem(transactions[index]);
              }, childCount: transactions.length));
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              List<Transaction> transactions = ref.watch(walletTransactions);
              bool isConnecting = ref.watch(connectingToNodeStateProvider);
              bool isWalletOpening = ref.watch(walletLoadingProvider) ?? false;
              Map<String, num>? sync = ref.watch(syncProgressStateProvider);
              bool isActive = isConnecting || isWalletOpening || sync != null;
              return SliverPadding(padding: EdgeInsets.all(isActive ? 24 : 0));
            },
          )
        ],
      ),
    );
  }

  Widget _buildTxItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      child: Consumer(
        builder: (context, ref, c) {
          return InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TxDetails(transaction: transaction),
                      fullscreenDialog: true));
            },
            child: TransactionItem(transaction: transaction),
          );
        },
      ),
    );
  }

  _buildViewOnlyMenu(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (item) {
        switch (item) {
          case 0:
            WalletChannel().rescan();
            break;
          case 1:
            exportOutput(context);
            break;
          case 2:
            importOutputs(context, callback: importKeyImages);
            break;
          case 3:
            doBroadcastStuff(context);
            break;
          case 4:
            importKeyImages(context);
            break;
          case 6:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OutputsScreen(),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          enabled: !isAirgapEnabled,
          child: const Text('Resync blockchain'),
        ),
        const PopupMenuItem<int>(
          value: 1,
          child: Text('Export Outputs'),
        ),
        const PopupMenuItem<int>(
          value: 3,
          child: Text('Broadcast Tx'),
        ),
        const PopupMenuItem<int>(
          value: 4,
          child: Text('Import Key Images'),
        ),
        const PopupMenuItem<int>(
          value: 6,
          child: Text('Coin Control'),
        ),
      ],
    );
  }

  _buildMenu(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (item) {
        switch (item) {
          case 0:
            WalletChannel().rescan();
            break;
          case 1:
            exportKeyImages(context);
            break;
          case 2:
            exportOutput(context);
            break;
          case 3:
            doBroadcastStuff(context);
            break;
          case 4:
            importUnsignedTx(context);
            break;
          case 5:
            importOutputs(context, callback: (_) {
              //Navigator.of(context).pop();
            });
            break;
          case 6:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OutputsScreen(),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: 0,
          enabled: !isAirgapEnabled,
          child: const Text("Resync blockchain"),
        ),
        const PopupMenuItem<int>(
          value: 1,
          child: Text('Export Key Images'),
        ),
        PopupMenuItem<int>(
          enabled: isAirgapEnabled,
          value: 5,
          child: const Text('Import Outputs'),
        ),
        const PopupMenuItem<int>(
          value: 4,
          child: Text('Sign Transaction'),
        ),
        const PopupMenuItem<int>(
          value: 6,
          child: Text('Coin Control'),
        ),
      ],
    );
  }

  void importUnsignedTx(BuildContext context) async {
    final navigator = Navigator.of(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pick Un signed Transaction File',
      allowMultiple: false,
    );
    if (result == null) return;
    bool impResult = await SpendMethodChannel()
            .importTxFile(result.files[0].path!, "unsigned") ??
        false;
    if (impResult) {
      navigator.push(MaterialPageRoute(
        builder: (context) {
          return AnonSpendForm(
            scannedType: UrType.xmrTxUnsigned,
            outputs: outputs!,
            maxAmount: maxAmount,
            goBack: () => print("transactions_list.dart: goBack()"),
          );
        },
      ));
    }
  }

  void importSignedTx(BuildContext context) async {
    final navigator = Navigator.of(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pick signed Transaction File',
      allowMultiple: false,
    );
    if (result == null) return;
    bool impResult = await SpendMethodChannel()
            .importTxFile(result.files[0].path!, "signed") ??
        false;
    if (impResult) {
      navigator.push(MaterialPageRoute(
        builder: (context) {
          return AnonSpendForm(
            scannedType: UrType.xmrTxSigned,
            maxAmount: maxAmount,
            outputs: outputs!,
            goBack: () => print("transactions_list.dart: goBack()1"),
          );
        },
      ));
    }
  }

  void importOutputs(BuildContext context,
      {required void Function(BuildContext context) callback}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import outputs',
      allowMultiple: false,
    );
    if (result == null) return;
    // await WalletChannel().setTrustedDaemon(true);
    final resp = await WalletChannel().importOutputsJ(result.files[0].path!);
    if (resp != "Imported") {
      scLog(context, resp.toString());
    }
    callback(context);
  }

  void exportKeyImages(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return ExportQRScreen(
          title: "KEY IMAGES",
          buttonText: "SCAN UNSIGNED TX",
          exportType: UrType.xmrKeyImage,
          counterScanCalled: (String data, newContext) async {
            // await BackUpRestoreChannel().exportFile(data);
            // navigateToHome(newContext);
            Future.delayed(Duration.zero).then((value) => widget.onScanClick());
          },
          onScanClick: widget.onScanClick,
        );
      },
    ));
  }

  void exportOutput(BuildContext context) async {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return ExportQRScreen(
          title: "OUTPUTS",
          exportType: UrType.xmrOutPut,
          buttonText: "SCAN KEY IMAGES",
          counterScanCalled: (String data, newContext) async {
            Future.delayed(Duration.zero).then((value) => widget.onScanClick());
          },
          onScanClick: widget.onScanClick,
        );
      },
    ));
  }
}

final generateURQR =
    FutureProvider.family<List<String>, String>((ref, path) async {
  var items = await anonCameraMethodChannel
      .invokeListMethod<String>("createUR", {"fpath": path});
  return items ?? List<String>.empty();
});

void signTx(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Import unsigned tx',
    allowMultiple: false,
  );
  if (result == null) return;
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final fpath = "${appDocumentsDir.path}/signed_monero_tx";
  if (await File(fpath).exists()) {
    File(fpath).delete();
  }
  await BackUpRestoreChannel().exportFile(fpath);
  // scLog(context, resp.toString());
}

void scLog(BuildContext context, String txt) async {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
}

String formatTime(int? timestamp) {
  if (timestamp == null) {
    return "";
  }
  var dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return DateFormat("HH:mm\ndd/M").format(dateTime);
}

void importKeyImages(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Pick file',
    allowMultiple: false,
  );
  if (result == null) return;
  await WalletChannel().setTrustedDaemon(true);
  final resp = await WalletChannel().importKeyImages(result.files[0].path!);
  scLog(context, resp.toString());
}

void doBroadcastStuff(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Pick file',
    allowMultiple: false,
  );
  if (result == null) return;
  final resp = await WalletChannel().submitTransaction(result.files[0].path!);
  scLog(context, resp.toString());
}
