import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/screens/home/settings/proxy_settings.dart';
import 'package:anon_wallet/screens/home/settings/settings_state.dart';
import 'package:anon_wallet/screens/onboard/onboard_state.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RestoreNodeSetup extends ConsumerWidget {
  final Function() onButtonPressed;
  final PageController pageController;
  final bool skipAppBar;

  const RestoreNodeSetup(
      {Key? key,
      required this.onButtonPressed,
      this.skipAppBar = false,
      required this.pageController})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Node? node = ref.watch(nodeConnectionProvider);

    String? nodeMessage;
    if (node != null && node.responseCode <= 200) {
      nodeMessage = "Connected to ${node.host}\nHeight : ${node.height}";
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          !skipAppBar
              ? SliverAppBar(
                  title: const Text("Node Setup"),
                  leading: IconButton(
                    onPressed: () {
                      pageController.previousPage(
                          curve: Curves.easeInOutQuad,
                          duration: const Duration(milliseconds: 500));
                    },
                    icon: const Icon(Icons.close),
                  ),
                )
              : const SliverToBoxAdapter(),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("NODE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: Column(
                children: [
                  TextFormField(
                    onChanged: (value) {
                      ref.read(remoteHost.state).state = value;
                    },
                    initialValue: ref.read(remoteHost.state).state,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 1),
                      ),
                      helperText: nodeMessage,
                      helperMaxLines: 3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'http://address.onion:port',
                    ),
                  ),
                  Consumer(builder: (context, ref, c) {
                    bool isConnecting =
                        ref.watch(connectingToNodeStateProvider);
                    if (isConnecting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: const LinearProgressIndicator(minHeight: 4)),
                      );
                    } else {
                      return const SizedBox();
                    }
                  })
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("USERNAME",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  ref.read(remoteUserName.state).state = value;
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '(optional)',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("PASSWORD",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                onChanged: (value) {
                  ref.read(remotePassword.state).state = value;
                },
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '(optional)',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    "ΛNON will only connect\nto the node specified above\n",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: HookConsumer(
              builder: (c, ref, child) {
                Proxy proxy = ref.watch(proxyStateProvider);
                useEffect(() {
                  ref.read(proxyStateProvider.notifier).getState();
                  return null;
                }, []);
                return Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(top: 24),
                  child: TextButton.icon(
                    style: ButtonStyle(
                        foregroundColor: proxy.isConnected()
                            ? MaterialStateColor.resolveWith(
                                (states) => Colors.green)
                            : MaterialStateColor.resolveWith(
                                (states) => Theme.of(context).primaryColor)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return const ProxySettings();
                        },
                      ));
                    },
                    label: const Text("Proxy Settings"),
                    icon: const Icon(Icons.shield_outlined),
                  ),
                );
              },
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(width: 1.0, color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          side:
                              const BorderSide(width: 12, color: Colors.white),
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 6)),
                  onPressed: () async {
                    if (ref.read(remoteHost).isEmpty) {
                      showConfirmColdAlertExternal(context, () {
                        onButtonPressed();
                      });
                    } else {
                      if (node != null) {
                        onButtonPressed();
                        return;
                      }
                      ref.read(nodeConnectionProvider.notifier).connect();
                    }
                  },
                  child: Text(node == null ? "Connect" : "Next"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showConfirmColdAlertExternal(BuildContext context, Function callback) {
    FocusNode focusNode = FocusNode();
    showDialog(
        context: context,
        barrierColor: barrierColor,
        barrierDismissible: false,
        builder: (context) {
          return HookBuilder(
            builder: (context) {
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
                        "Do you want to create an offline wallet? Using this option will not use any node and will operate in a fully-offline way. You will need a separate wallet to sign transactions.",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        onButtonPressed();
                      },
                      child: const Text("Confirm"))
                ],
              );
            },
          );
        });
  }
}
