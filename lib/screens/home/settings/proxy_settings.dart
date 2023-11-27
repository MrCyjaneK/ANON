import 'package:anon_wallet/screens/home/settings/settings_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/utils/embed_tor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxySettings extends HookConsumerWidget {
  const ProxySettings({super.key});

  @override
  Widget build(BuildContext context, ref) {
    var proxyTextEditingController =
        useTextEditingController(text: "127.0.0.1");
    var portTorTextEditingController = useTextEditingController(text: "9050");
    var portI2pTextEditingController = useTextEditingController(text: "4447");

    useEffect(() {
      ref.read(proxyStateProvider.notifier).getState().then((value) {
        Proxy proxy = ref.read(proxyStateProvider);
        if (proxy.serverUrl.isNotEmpty) {
          proxyTextEditingController.text = proxy.serverUrl;
        }
        if (proxy.portTor.isNotEmpty) {
          portTorTextEditingController.text = proxy.portTor;
        }
        if (proxy.portI2p.isNotEmpty) {
          portI2pTextEditingController.text = proxy.portI2p;
        }
      });
      return () {
        proxyTextEditingController.text = "";
        portTorTextEditingController.text = "";
        portI2pTextEditingController.text = "";
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Proxy Settings"),
        centerTitle: false,
      ),
      body: Column(
        children: [
          ListTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "SERVER",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
            subtitle: TextField(
              controller: proxyTextEditingController,
              onChanged: (value) {},
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          ListTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "TOR PORT",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            subtitle: TextField(
              onChanged: (value) {},
              controller: portTorTextEditingController,
              textInputAction: TextInputAction.next,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          ListTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "I2P PORT",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ),
            subtitle: TextField(
              onChanged: (value) {},
              controller: portI2pTextEditingController,
              textInputAction: TextInputAction.next,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (proc != null)
            Expanded(
              child: SizedBox.square(
                dimension: 128,
                child: IconButton(
                  alignment: Alignment.center,
                  icon: const Icon(
                    Icons.refresh,
                    size: 128,
                  ),
                  onPressed: () {
                    SnackBar snackBar = SnackBar(
                      backgroundColor: Colors.grey[900],
                      content: Text('Embedded tor identity changed',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.white)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    runEmbeddedTor();
                  },
                ),
              ),
            ),
          if (proc == null) const Spacer(),
          const Padding(padding: EdgeInsets.all(8)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: OutlinedButton(
                onPressed: () async {
                  try {
                    await ref.read(proxyStateProvider.notifier).setProxy(
                        proxyTextEditingController.text,
                        portTorTextEditingController.text,
                        portI2pTextEditingController.text);
                    SnackBar snackBar = SnackBar(
                      backgroundColor: Colors.grey[900],
                      content: Text('Proxy enabled',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.white)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pop(context);
                  } on PlatformException catch (e) {
                    SnackBar snackBar = SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.grey[900],
                      content: Text('Error : ${e.message}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.white)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  } catch (e) {
                    print(e);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(width: 1.0, color: Colors.white),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 12, color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                ),
                child: Text(
                  "SET",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white),
                )),
          ),
          if (kDebugMode)
            Opacity(
              opacity: !kReleaseMode ? 1 : 0,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: TextButton(
                  onPressed: () async {
                    await ref
                        .read(proxyStateProvider.notifier)
                        .setProxy("", "", "");
                    SnackBar snackBar = SnackBar(
                      backgroundColor: Colors.grey[900],
                      content: Text('Proxy disabled',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: Colors.white)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Disable proxy",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.red),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
