import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class WalletPassphraseWidget extends StatelessWidget {
  final Function(String value) onPassSeedPhraseAdded;

  WalletPassphraseWidget(
      {Key? key,
      required this.onPassSeedPhraseAdded,
      required this.heroEnabled})
      : super(key: key);
  final TextEditingController passPhraseController = TextEditingController();

  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 120,
      child: CustomScrollView(
        slivers: [
          if (heroEnabled)
            SliverToBoxAdapter(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                      tag: "anon_logo",
                      child: SizedBox(
                          width: 180,
                          child: Image.asset("assets/anon_logo.png"))),
                ],
              ),
            ),
          SliverToBoxAdapter(
            child: Center(
              child: Text(
                "PASSPHRASE ENCRYPTION",
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 22, color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("ENTER PASSPHRASE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                controller: passPhraseController,
                enableIMEPersonalizedLearning: false,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.white, width: 1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                  ),
                  hintText: '',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text("CONFIRM PASSPHRASE",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ),
              subtitle: TextField(
                enableIMEPersonalizedLearning: false,
                enableSuggestions: false,
                autocorrect: false,
                onChanged: (String value) {
                  if (passPhraseController.text == value) {
                    onPassSeedPhraseAdded(value);
                  } else {
                    onPassSeedPhraseAdded("");
                  }
                },
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                    borderSide: BorderSide(color: Colors.white, width: 1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                  ),
                  hintText: '',
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
                    "Enter your seed passphrase\n",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                      "NOTE: Passphrase is required\nto restore from\nseed or backup file",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
