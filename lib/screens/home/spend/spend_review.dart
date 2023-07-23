import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/models/broadcast_tx_state.dart';
import 'package:anon_wallet/screens/home/spend/spend_state.dart';
import 'package:anon_wallet/screens/home/wallet_home.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AnonSpendReview extends ConsumerWidget {
  final Function? onActionClicked;

  const AnonSpendReview({Key? key, this.onActionClicked}) : super(key: key);

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
                      navigateToHome(context);
                    },
                  )),
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
                subTitle: "${formatMonero(amount)} XMR",
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SpendListItem(
                title: "Fee",
                isLoading: loading,
                subTitle:
                    "${formatMonero((fees ?? 0), minimumFractions: 8)} XMR",
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SpendListItem(
                title: "Total",
                isLoading: loading,
                subTitle:
                    "${formatMonero((fees ?? 0) + (amount ?? 0), minimumFractions: 8)} XMR",
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
                      side: BorderSide(width: 1.0, color: loading ? Colors.white54 : Colors.white),
                      foregroundColor: loading ? Colors.white54 : Colors.white,
                      shape: RoundedRectangleBorder(
                          side: BorderSide(width: 12, color: loading ? Colors.white54 : Colors.white),
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6)),
                  onPressed: () {
                    onActionClicked?.call();
                  },
                  child: const Text("Confirm")),
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

  const SpendListItem(
      {Key? key,
      required this.title,
      this.isLoading = false,
      required this.subTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).primaryColor)),
      trailing: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: isLoading
            ? Container(
                width: 12,
                height: 12,
                child: const CircularProgressIndicator(strokeWidth: 1),
              )
            : Text(
                subTitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 18),
              ),
      ),
    );
  }
}
