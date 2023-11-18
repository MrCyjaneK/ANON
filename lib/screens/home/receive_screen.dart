import 'package:anon_wallet/screens/home/subaddress/edit_sub_address.dart';
import 'package:anon_wallet/screens/home/subaddress/sub_addresses.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveWidget extends ConsumerWidget {
  final VoidCallback callback;

  const ReceiveWidget(this.callback, {super.key});

  @override
  Widget build(BuildContext context, ref) {
    var subAddress = ref.watch(currentSubAddressProvider);
    var address = subAddress?.address ?? "";
    if (address == "") return const Scaffold();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            leading: BackButton(
              onPressed: () {
                callback();
              },
            ),
            actions: [
              IconButton(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const SubAddressesList();
                        },
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.history))
            ],
          ),
          const SliverPadding(padding: EdgeInsets.all(8)),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () {
                showDialog(
                    barrierColor: const Color(0xab1e1e1e),
                    context: context,
                    builder: (context) {
                      return SubAddressEditDialog(subAddress!);
                    });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    "${subAddress?.getLabel()}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 26),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.all(8)),
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: QrImageView(
                  backgroundColor: Colors.black,
                  gapless: false,
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.white),
                  eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square, color: Colors.white),
                  data: address,
                  version: QrVersions.auto,
                  //size: 280.0,
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.all(8)),
          SliverToBoxAdapter(
            child: GestureDetector(
              onLongPress: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const SubAddressesList();
                  },
                  fullscreenDialog: true,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                subtitle: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: address));
                  },
                  child: Center(
                    child: Text(
                      address,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontSize: 17),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
