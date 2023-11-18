import 'dart:convert';

import 'package:anon_wallet/models/broadcast_tx_state.dart';
import 'package:anon_wallet/screens/home/spend/spend_state.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AnonSpendReview extends ConsumerWidget {
  final Function? onActionClicked;

  const AnonSpendReview({super.key, this.onActionClicked});
  void showFeeNotification(
      BuildContext context, Function? onActionClicked) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text(
          "Huge fee detected!",
        ),
        content: const Text(
            'It looks like you are trying to send a transaction with a huge fee '
            'while this may be intentional (you are sending a small amount of '
            'monero), chances are that you are connected to malicious node.\n'
            'We recommend you to switch node and make sure that you want to '
            'pay fee this big.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          OutlinedButton(
            onPressed: () => onActionClicked?.call(),
            child: const Text("Send anyway"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextStyle? titleTheme = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: Theme.of(context).primaryColor);
    String address = ref.watch(addressStateProvider);
    String notes = ref.watch(notesStateProvider);
    TxState txState = ref.watch(transactionStateProvider);
    var fees = txState.fee;
    var amount = txState.amount;
    bool loading = txState.isLoading();
    bool hasError = txState.hasError();

    if (txState.address != null && txState.address!.isNotEmpty) {
      address = txState.address!;
    }
    if (hasError) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              toolbarHeight: 120,
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Hero(
                    tag: "anon_logo",
                    child: SizedBox(
                        width: 160, child: Image.asset("assets/anon_logo.png")),
                  )),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    title: Text("Address", style: titleTheme),
                    subtitle: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )),
            ),
            SliverToBoxAdapter(
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  "Error ${txState.errorString}",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.red),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                alignment: Alignment.center,
                child: TextButton(
                  child: const Text("Close"),
                  onPressed: () {
                    // navigateToHome(context);
                    Future.delayed(const Duration(milliseconds: 222)).then(
                      (_) => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (c) => const WalletHome(startScreen: 0),
                            settings: const RouteSettings(name: "/")),
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 120,
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Hero(
                  tag: "anon_logo",
                  child: SizedBox(
                      width: 160, child: Image.asset("assets/anon_logo.png")),
                )),
          ),
          if (kDebugMode)
            SliverToBoxAdapter(
              child: SelectableText(
                  const JsonEncoder.withIndent('    ').convert(txState)),
            ),
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListTile(
                  title: Text("Address", style: titleTheme),
                  subtitle: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )),
          ),
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListTile(
                  title: Text("Description", style: titleTheme),
                  subtitle: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      notes.isNotEmpty ? notes : "N/A",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SpendListItem(
                title: "Amount",
                isLoading: loading,
                subTitle: formatMonero(amount),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SpendListItem(
                title: "Fee",
                isLoading: loading,
                subTitle: formatMonero((fees ?? 0)),
                color: (((fees ?? 0) == 0) ||
                        ((amount ?? 0) == 0) ||
                        (amount ?? 0) * 0.10 < (fees ?? 0))
                    ? Colors.red
                    : null,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SpendListItem(
                title: "Total",
                isLoading: loading,
                subTitle: formatMonero((fees ?? 0) + (amount ?? 0)),
              ),
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
                      side: BorderSide(
                          width: 1.0,
                          color: loading ? Colors.white54 : Colors.white),
                      foregroundColor: loading ? Colors.white54 : Colors.white,
                      shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 12,
                              color: loading ? Colors.white54 : Colors.white),
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 6)),
                  onPressed: () {
                    final fee = fees ?? 0;
                    final amt = amount ?? 0;
                    if ((fee == 0) || (amt == 0) || (amt * 0.10 < fee)) {
                      showFeeNotification(context, onActionClicked);
                    } else {
                      onActionClicked?.call();
                    }
                  },
                  child: const Text("CONFIRM")),
            ),
          );
        }),
      ),
    );
  }
}

class SpendListItem extends StatelessWidget {
  final String title;
  final String subTitle;
  final bool isLoading;
  final Color? color;
  const SpendListItem(
      {super.key,
      required this.title,
      this.isLoading = false,
      required this.subTitle,
      this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Theme.of(context).primaryColor),
      ),
      trailing: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1),
              )
            : Text(
                subTitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 18, color: color),
              ),
      ),
    );
  }
}
