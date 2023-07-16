import 'package:anon_wallet/models/sub_address.dart';
import 'package:anon_wallet/screens/home/subaddress/edit_sub_address.dart';
import 'package:anon_wallet/screens/home/transactions/tx_details.dart';
import 'package:anon_wallet/screens/home/transactions/tx_item_widget.dart';
import 'package:anon_wallet/state/sub_addresses.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../models/transaction.dart';

class SubAddressDetails extends ConsumerStatefulWidget {
  final SubAddress subAddress;

  const SubAddressDetails({Key? key, required this.subAddress})
      : super(key: key);

  @override
  ConsumerState<SubAddressDetails> createState() => _SubAddressDetailsState();
}

class _SubAddressDetailsState extends ConsumerState<SubAddressDetails> {
  @override
  Widget build(BuildContext context) {
    SubAddress subAddress = ref.watch(getSpecificSubAddress(widget.subAddress));
    List<Transaction> transactions = ref.watch(subAddressDetails(subAddress));
    return Scaffold(
      appBar: AppBar(
        actions: [
          Builder(builder: (context) {
            return IconButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: subAddress.address.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("address copied",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white)),
                    backgroundColor: Colors.grey[900],
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                icon: const Icon(Icons.copy));
          }),
          IconButton(
              onPressed: () {
                showDialog(
                    barrierColor: barrierColor,
                    context: context,
                    builder: (context) {
                      return SubAddressEditDialog(subAddress);
                    });
              },
              icon: const Icon(Icons.edit)),
          Builder(builder: (context) {
            return IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: SizedBox.square(
                          dimension: 280,
                          child: Center(
                            child: QrImageView(
                              size: 280,
                              backgroundColor: Colors.black,
                              data: "monero:${subAddress.address}",
                              version: QrVersions.auto,
                              eyeStyle: const QrEyeStyle(
                                  color: Colors.white,
                                  eyeShape: QrEyeShape.square),
                              dataModuleStyle: const QrDataModuleStyle(
                                  color: Colors.white,
                                  dataModuleShape: QrDataModuleShape.square),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.qr_code_2_outlined));
          })
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              child: Hero(
                tag: "sub:${subAddress.squashedAddress}",
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    title: Text(
                      subAddress.label ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                    subtitle: Text(subAddress.address ?? ''),
                    trailing: Text(
                      formatMonero(subAddress.totalAmount),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              TxDetails(transaction: transactions[index]),
                          fullscreenDialog: true));
                },
                child: TransactionItem(
                  transaction: transactions[index],
                ),
              ),
            );
          }, childCount: transactions.length)),
          SliverToBoxAdapter(
            child: transactions.isEmpty
                ? Container(
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text("No transactions yet..",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ),
                  )
                : const SizedBox(),
          )
        ],
      ),
    );
  }
}
