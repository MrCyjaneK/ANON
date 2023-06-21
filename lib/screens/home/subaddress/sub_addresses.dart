import 'package:anon_wallet/channel/address_channel.dart';
import 'package:anon_wallet/models/sub_address.dart';
import 'package:anon_wallet/screens/home/subaddress/edit_sub_address.dart';
import 'package:anon_wallet/screens/home/subaddress/sub_address_details.dart';
import 'package:anon_wallet/state/sub_addresses.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SubAddressesList extends ConsumerStatefulWidget {
  const SubAddressesList({Key? key}) : super(key: key);

  @override
  ConsumerState<SubAddressesList> createState() => _SubAddressesListState();
}

class _SubAddressesListState extends ConsumerState<SubAddressesList> {
  @override
  void initState() {
    super.initState();
    AddressChannel().getSubAddresses();
  }

  @override
  Widget build(BuildContext context) {
    var value = ref.watch(getSubAddressesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("SubAddresses"),
      ),
      body: value.map(
          data: (data) {
            List<SubAddress> used = data.value
                .where((element) => element.totalAmount != 0)
                .toList();
            List<SubAddress> unUsed = data.value
                .where((element) => element.totalAmount == 0)
                .toList();
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: used.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            color: Colors.grey[900],
                            child: Text("Used Addresses",
                                style: Theme.of(context).textTheme.titleSmall))
                        : const SizedBox()),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                  childCount: used.length,
                  (context, index) => SubAddressItem(used[index]),
                )),
                SliverToBoxAdapter(
                    child: unUsed.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            color: Colors.grey[900],
                            child: Text("Unused Addresses",
                                style: Theme.of(context).textTheme.titleSmall))
                        : const SizedBox()),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                  childCount: unUsed.length,
                  (context, index) => SubAddressItem(unUsed[index]),
                )),
                const SliverPadding(padding: EdgeInsets.all(44))
              ],
            );
          },
          error: (error) => Center(child: Text("Error $error")),
          loading: (c) => const Center(
                child: SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(),
                ),
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddressChannel().deriveNewSubAddress();
        },
        backgroundColor: Theme.of(context).primaryColor,
        label: Text("New SubAddress",
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class SubAddressItem extends StatelessWidget {
  final SubAddress subAddress;

  const SubAddressItem(this.subAddress, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "sub:${subAddress.squashedAddress}",
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) {
              return SubAddressDetails(
                subAddress: subAddress,
              );
            }));
          },
          onLongPress: () {
            showDialog(
                barrierColor: barrierColor,
                context: context,
                builder: (context) {
                  return SubAddressEditDialog(subAddress);
                });
          },
          title: Text(
            subAddress.getLabel(),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).primaryColor),
          ),
          subtitle: Text("${subAddress.squashedAddress}"),
          trailing: Text(
            formatMonero(subAddress.totalAmount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
