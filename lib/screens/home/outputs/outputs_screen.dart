import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/screens/home/outputs/tx_output_element.dart';
import 'package:anon_wallet/screens/home/spend/spend_form_main.dart';
import 'package:anon_wallet/utils/monetary_util.dart';
import 'package:flutter/material.dart';

class OutputsScreen extends StatefulWidget {
  const OutputsScreen({Key? key}) : super(key: key);

  @override
  State<OutputsScreen> createState() => _OutputsScreenState();
}

class _OutputsScreenState extends State<OutputsScreen> {
  List<dynamic>? outputs;

  @override
  void initState() {
    WalletChannel().getUtxos().then((value) {
      final tmpval = [];
      value.forEach((key, value) {
        if (!value["spent"]) {
          tmpval.add(value);
        }
      });
      setState(() {
        outputs = tmpval;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: outputs == null
          ? const LinearProgressIndicator()
          : ListView.builder(
              itemCount: outputs!.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  value: outputs![index]["is_selected"] == true,
                  subtitle: TxOutputElement(
                    utxo: outputs![index],
                    index: index,
                  ),
                  onChanged: (bool? value) {
                    setState(() {
                      outputs![index]["is_selected"] = value == true;
                    });
                  },
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(width: 1.0, color: Colors.white),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 12, color: Colors.white),
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6)),
          onPressed: outputs == null || getOutputTotal() == 0
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        final outs = <String>[];
                        num maxAmount = 0;
                        for (var output in outputs!) {
                          if (output["is_selected"] == true) {
                            outs.add(output["keyImage"]);
                            maxAmount += output["amount"];
                          }
                        }
                        return AnonSpendForm(
                            outputs: outs,
                            maxAmount: maxAmount,
                            addAppBar: true,
                            // onValidationComplete: () {
                            //   print('output_screen.dart on validate complete');
                            // },
                            goBack: () =>
                                print("outputs_screen.dart: goBack()"));
                      },
                    ),
                  );
                },
          child: Text("Send ${formatMonero(getOutputTotal())} XMR"),
        ),
      ),
    );
  }

  Future<dynamic> showSendDialog(BuildContext context) {
    final addressCtrl = TextEditingController();
    final amountCtrl =
        TextEditingController(text: getAmountFull(getOutputTotal()));
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Send"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Selected amount: ${getAmountFull(getOutputTotal())}"),
              TextField(controller: addressCtrl),
              TextField(controller: amountCtrl),
            ],
          ),
        );
      },
    );
  }

  num getOutputTotal() {
    num amt = 0;
    if (outputs == null) return 0;
    for (var output in outputs!) {
      if (output["is_selected"] == true) {
        amt += output["amount"];
      }
    }
    return amt;
  }

  String getAmountFull(num amt) => ((amt / 1e12)).toStringAsFixed(12);
}
