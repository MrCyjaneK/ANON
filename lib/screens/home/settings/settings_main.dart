import 'dart:async';
import 'dart:math';

import 'package:anon_wallet/anon_wallet.dart';
import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/screens/home/settings/nodes/nodes_settings.dart';
import 'package:anon_wallet/screens/home/settings/proxy_settings.dart';
import 'package:anon_wallet/screens/home/settings/settings_state.dart';
import 'package:anon_wallet/screens/home/settings/view_wallet_private.dart';
import 'package:anon_wallet/state/node_state.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/app_haptics.dart';
import 'package:anon_wallet/utils/embed_tor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    TextStyle? titleStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: Theme.of(context).primaryColor);
    Color? dividerColor = Colors.grey[700];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                !isAirgapEnabled
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Text("Connection", style: titleStyle),
                      )
                    : const SizedBox.shrink(),
                !isAirgapEnabled
                    ? Divider(color: dividerColor, height: 2)
                    : const SizedBox.shrink(),
                !isAirgapEnabled
                    ? ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 34),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NodesSettingsScreens(),
                            ),
                          );
                        },
                        title: const Text("Node"),
                        subtitle: Text(
                          "Manage nodes",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: dividerColor),
                        ),
                      )
                    : const SizedBox.shrink(),
                Divider(color: dividerColor, height: 2),
                !isAirgapEnabled
                    ? HookConsumer(builder: (context, ref, child) {
                        Proxy proxy = ref.watch(proxyStateProvider);
                        bool isConnected = ref.watch(connectionStatus);
                        useEffect(() {
                          ref.read(proxyStateProvider.notifier).getState();
                          ref.read(proxyStateProvider.notifier).getState();
                          return null;
                        }, []);
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProxySettings()));
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isConnected ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          title: const Text("Proxy"),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 34),
                          subtitle: proxy.isConnected()
                              ? null
                              : Text("Disabled",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: dividerColor)),
                        );
                      })
                    : const SizedBox.shrink(),
                Divider(color: dividerColor, height: 2),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text("Security", style: titleStyle),
                ),
                Divider(color: dividerColor, height: 2),
                Opacity(
                  opacity: 0.4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                    onTap: () {},
                    title: const Text("Change Pin"),
                  ),
                ),
                Divider(color: dividerColor, height: 2),
                ListTile(
                  enabled: !isViewOnly,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ViewWalletSeed()));
                  },
                  title: const Text("View Seed"),
                ),
                Divider(color: dividerColor, height: 2),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                  onTap: () {
                    showBackUpDialog(context);
                  },
                  title: const Text("Export Backup"),
                ),
                Divider(color: dividerColor, height: 2),
                Consumer(
                  builder: (context, ref, child) {
                    bool isConnecting =
                        ref.watch(connectingToNodeStateProvider);
                    bool isWalletOpening =
                        ref.watch(walletLoadingProvider) ?? false;
                    bool isLoading = isConnecting || isWalletOpening;

                    return Opacity(
                      opacity: isLoading ? 0.4 : 1,
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 34),
                        onTap: !isLoading
                            ? () {
                                showWipeDialog(context);
                              }
                            : null,
                        title: const Text("Secure Wipe"),
                      ),
                    );
                  },
                ),
                Divider(color: dividerColor, height: 2),
              ],
            ),
          )
        ],
      ),
    );
  }

  void showBackUpDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierColor: barrierColor,
        barrierDismissible: false,
        builder: (context) {
          return const BackupDialog();
        });
  }

  void showWipeDialog(BuildContext context) {
    showDialog(
        context: context,
        barrierColor: barrierColor,
        barrierDismissible: true,
        builder: (context) {
          return const WipeDialog();
        });
  }
}

class WipeDialog extends HookWidget {
  const WipeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = useTextEditingController();
    FocusNode focusNode = useFocusNode();

    const inputBorder =
        UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent));

    var error = useState<String?>(null);
    var loading = useState<bool>(false);
    useEffect(() {
      focusNode.requestFocus();
      return null;
    }, []);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 1.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter Passphrase to confirm",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            TextField(
                focusNode: focusNode,
                controller: controller,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                obscureText: true,
                obscuringCharacter: "*",
                decoration: InputDecoration(
                    errorText: error.value,
                    fillColor: Colors.grey[900],
                    filled: true,
                    focusedBorder: inputBorder,
                    border: inputBorder,
                    errorBorder: inputBorder)),
            loading.value
                ? const LinearProgressIndicator(
                    minHeight: 1,
                  )
                : const SizedBox()
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
              try {
                loading.value = true;
                focusNode.unfocus();
                await WalletChannel().wipe(controller.text);
                bool isSuccess =
                    await BackUpRestoreChannel().makeBackup(controller.text);
                AppHaptics.lightImpact();
                if (!isSuccess) {
                  Navigator.pop(context);
                }
                loading.value = false;
              } on PlatformException catch (e, s) {
                debugPrintStack(stackTrace: s);
                error.value = e.message;
                loading.value = false;
              } catch (e) {
                loading.value = false;
                error.value = "Error $e";
              }
            },
            child: const Text("Confirm"))
      ],
    );
  }
}

class BackupDialog extends HookWidget {
  const BackupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    PageController pageController = usePageController();
    TextEditingController controller = useTextEditingController();
    FocusNode focusNode = useFocusNode();

    const inputBorder =
        UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent));
    var error = useState<String?>(null);
    var loading = useState<bool>(false);
    useEffect(() {
      focusNode.requestFocus();
      return null;
    }, []);
    return PageView(
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  "Enter Passphrase",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Padding(padding: EdgeInsets.all(12)),
                TextField(
                    focusNode: focusNode,
                    controller: controller,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    obscuringCharacter: "*",
                    decoration: InputDecoration(
                        errorText: error.value,
                        fillColor: Colors.grey[900],
                        filled: true,
                        focusedBorder: inputBorder,
                        border: inputBorder,
                        errorBorder: inputBorder)),
                loading.value
                    ? const LinearProgressIndicator(
                        minHeight: 1,
                      )
                    : const SizedBox()
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
                  try {
                    loading.value = true;
                    focusNode.unfocus();
                    await Future.delayed(const Duration(milliseconds: 310));
                    await pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInSine);
                    bool isSuccess = await BackUpRestoreChannel()
                        .makeBackup(controller.text);
                    AppHaptics.lightImpact();
                    if (!isSuccess) {
                      Navigator.pop(context);
                    }
                    loading.value = false;
                  } on PlatformException catch (e, s) {
                    debugPrintStack(stackTrace: s);
                    await pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInSine);
                    error.value = e.message;
                    loading.value = false;
                  } catch (e) {
                    pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInSine);
                    loading.value = false;
                    error.value = "Error $e";
                  }
                },
                child: const Text("Confirm"))
          ],
        ),
        AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 1.3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Creating Backup",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                loading.value
                    ? const Padding(
                        padding: EdgeInsets.only(top: 34),
                        child: Center(
                          child: SizedBox.square(
                            dimension: 62,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 34, bottom: 12),
                            child: Center(
                                child: Icon(
                              Icons.check_circle,
                              size: 60,
                            )),
                          ),
                          Text(
                            "Backup Created",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      )
              ],
            ),
          ),
          actions: [
            !loading.value
                ? TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Ok"))
                : Container(),
          ],
        ),
      ],
    );
  }
}
