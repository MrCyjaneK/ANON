import 'package:animations/animations.dart';
import 'package:anon_wallet/models/broadcast_tx_state.dart';
import 'package:anon_wallet/screens/home/spend/spend_state.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
//
// class SpendProgressWidget extends ConsumerWidget {
//   final VoidCallback onCloseCallBack;
//
//   const SpendProgressWidget({Key? key, required this.onCloseCallBack})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     TxState txState = ref.watch(transactionStateProvider);
//     String state = txState.state;
//     bool hasError = txState.hasError();
//     bool isLoading = txState.isLoading();
//
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             toolbarHeight: 120,
//             bottom: PreferredSize(
//                 preferredSize: const Size.fromHeight(60),
//                 child: Hero(
//                   tag: "anon_logo",
//                   child: SizedBox(
//                       width: 160, child: Image.asset("assets/anon_logo.png")),
//                 )),
//           ),
//           SliverFillRemaining(
//               hasScrollBody: false,
//               child: Container(
//                 padding: const EdgeInsets.only(top: 12),
//                 child: PageTransitionSwitcher(
//                   reverse: false,
//                   transitionBuilder: (Widget child,
//                       Animation<double> animation,
//                       Animation<double> secondaryAnimation,) {
//                     return SharedAxisTransition(
//                       animation: animation,
//                       fillColor: Colors.transparent,
//                       secondaryAnimation: secondaryAnimation,
//                       transitionType: SharedAxisTransitionType.vertical,
//                       child: child,
//                     );
//                   },
//                   duration: const Duration(milliseconds: 400),
//                   child: isLoading
//                       ? _showLoader(context)
//                       : hasError
//                       ? _showError(context, txState)
//                       : _showSuccess(context, txState),
//                 ),
//               ))
//         ],
//       ),
//     );
//   }
//
//   _showLoader(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         const Spacer(),
//         SizedBox.fromSize(
//           size: const Size(280, 280),
//           child: const CircularProgressIndicator(
//             strokeWidth: 1,
//           ),
//         ),
//         const Spacer(),
//         Text("Constructing transaction",
//             style: Theme
//                 .of(context)
//                 .textTheme
//                 .titleLarge),
//         const Spacer(),
//       ],
//     );
//   }
//
//   _showSuccess(BuildContext context, TxState txState) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 28),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           const Spacer(),
//           Icon(
//             Icons.check_circle,
//             size: 180,
//             color: Theme
//                 .of(context)
//                 .primaryColor,
//           ),
//           const Text("Successfully sent transaction."),
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 34),
//             child: SelectableText(txState.txId ?? ""),
//           ),
//           TextButton(
//               onPressed: () {
//                 onCloseCallBack();
//               },
//               child: const Text("close")),
//           const Spacer(),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
//
//   _showError(BuildContext context, TxState txState) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 28),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           const Spacer(),
//           const Icon(
//             Icons.error_outline,
//             size: 180,
//             color: Colors.red,
//           ),
//           const Text("Error broadcasting transaction"),
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 40),
//             child: SelectableText(txState.errorString ?? ""),
//           ),
//           TextButton(
//               onPressed: () {
//                 onCloseCallBack();
//               },
//               child: const Text("close")),
//           const Spacer(),
//           const Spacer(),
//         ],
//       ),
//     );
//   }
// }

class SpendSuccessWidget extends ConsumerWidget {
  const SpendSuccessWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TxState txState = ref.watch(transactionStateProvider);
    String state = txState.state;
    bool hasError = txState.hasError();
    bool isLoading = txState.isLoading();

    return WillPopScope(
      onWillPop: () {
        Navigator.popUntil(context, (route) => route.settings.name == "/");
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.popUntil(
                  context, (route) => route.settings.name == "/");
            },
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.check_circle,
                  size: 180,
                  color: Theme.of(context).primaryColor,
                ),
                const Text("Successfully sent transaction."),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 44),
                  child: SelectableText(txState.txId ?? "",
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.popUntil(
                          context, (route) => route.settings.name == "/");
                    },
                    child: const Text("close")),
                const Spacer(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
