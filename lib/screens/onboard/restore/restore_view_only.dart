import 'dart:convert';

import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:anon_wallet/screens/onboard/restore/restore_node_setup.dart';
import 'package:anon_wallet/screens/set_pin_screen.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:anon_wallet/widgets/qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RestoreViewOnlyWallet extends StatefulWidget {
  const RestoreViewOnlyWallet({Key? key}) : super(key: key);

  @override
  State<RestoreViewOnlyWallet> createState() => _RestoreViewOnlyWalletState();
}

class _RestoreViewOnlyWalletState extends State<RestoreViewOnlyWallet> {
  final PageController _pageController = PageController();

  bool canScan = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _pageController,
      children: [
        Column(
          children: [
            Center(
              child: Hero(
                  tag: "anon_logo",
                  child: SafeArea(
                      child: SizedBox(
                          width: 180,
                          child: Image.asset("assets/anon_logo.png")))),
            ),
            Center(
              child: Text(
                "NODE CONNECTION",
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 22, color: Colors.white),
              ),
            ),
            Expanded(
              child: RestoreNodeSetup(
                onButtonPressed: () {
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease);
                  setState(() {
                    canScan = true;
                  });
                },
                skipAppBar: true,
                pageController: _pageController,
              ),
            )
          ],
        ),
        Column(
          children: [
            Center(
              child: Hero(
                  tag: "anon_logo",
                  child: SafeArea(
                      child: SizedBox(
                          width: 180,
                          child: Image.asset("assets/anon_logo.png")))),
            ),
            Text(
              "VIEW ONLY KEYS",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Expanded(
              child: ImportViewOnlyKeys(
                  pageController: _pageController,
                  onDone: () {
                    setState(() {
                      canScan = false;
                    });
                  }),
            ),
          ],
        ),
        Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    Hero(
                        tag: "anon_logo",
                        child: SizedBox(
                            width: 180,
                            child: Image.asset("assets/anon_logo.png"))),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text("Restoring wallet..."),
                )
              ],
            ),
          ),
        )
      ],
    ));
  }
}

class ImportViewOnlyKeys extends StatefulWidget {
  final PageController pageController;

  const ImportViewOnlyKeys(
      {Key? key, required this.pageController, required this.onDone})
      : super(key: key);

  final Function() onDone;

  @override
  State<ImportViewOnlyKeys> createState() => _ImportViewOnlyKeysState();
}

class _ImportViewOnlyKeysState extends State<ImportViewOnlyKeys> {
  final TextEditingController _primaryAddress = TextEditingController();
  String? _primaryAddressError;
  String? _privateViewKeyError;
  final TextEditingController _privateViewKey = TextEditingController();
  final TextEditingController _restoreHeight = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("PRIMARY ADDRESS",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                onChanged: (value) {
                  setState(() {});
                },
                controller: _primaryAddress,
                maxLines: 1,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  errorText: _primaryAddressError,
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
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("PRIVATE VIEW KEY",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                onChanged: (value) {
                  setState(() {});
                },
                maxLines: 1,
                controller: _privateViewKey,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  errorText: _privateViewKeyError,
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
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("RESTORE HEIGHT",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                onChanged: (value) {
                  setState(() {});
                },
                controller: _restoreHeight,
                maxLines: 1,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: false, signed: true),
                textInputAction: TextInputAction.done,
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Container(
                alignment: Alignment.center,
                child: IconButton(
                  iconSize: 72,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => QRScannerView(
                        onScanCallback: (value) async {
                          final data = json.decode(value.text);
                          setState(() {
                            _primaryAddress.text = data['primaryAddress'];
                            _privateViewKey.text = data['privateViewKey'];
                            _restoreHeight.text =
                                data['restoreHeight'].toString();
                          });
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.crop_free_sharp),
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.bottomRight,
        child: Builder(builder: (context) {
          bool isActive = (_primaryAddress.text.isNotEmpty &&
              _privateViewKey.text.isNotEmpty &&
              num.tryParse(_restoreHeight.text) != null);
          return OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: isActive ? Colors.white : Colors.white24,
                side: BorderSide(
                  width: 1.0,
                  color: isActive ? Colors.white : Colors.white24,
                ),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                        width: 12,
                        color: isActive ? Colors.white : Colors.white24),
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 6)),
            onPressed: isActive
                ? () async {
                    try {
                      FocusScope.of(context).requestFocus(FocusNode());
                      String? pin =
                          await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const SetPinScreen(
                          title: "Set up pin",
                        ),
                      ));
                      if (pin != null && pin.isNotEmpty) {
                        await widget.pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease);
                        await BackUpRestoreChannel().restoreViewOnly(
                            _primaryAddress.text,
                            _privateViewKey.text,
                            num.parse(_restoreHeight.text),
                            pin);
                      }
                    } on PlatformException catch (exception) {
                      widget.pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease);
                      if (exception.code == "primaryAddress") {
                        setState(() {
                          _primaryAddressError = exception.message;
                        });
                      }
                      if (exception.code == "privateViewKey") {
                        setState(() {
                          _privateViewKeyError = exception.message;
                        });
                      }
                    } catch (e) {
                      // widget.pageController
                      //     .previousPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
                    }
                  }
                : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 44),
              child: Text("Next"),
            ),
          );
        }),
      ),
    );
  }
}
