import 'package:flutter/material.dart';

class TxOutputElement extends StatelessWidget {
  const TxOutputElement({
    Key? key,
    required this.utxo,
    required this.index,
  }) : super(key: key);

  final int index;
  final /* Map<String, dynamic> */ dynamic utxo;

  @override
  Widget build(BuildContext context) {
    // if (kDebugMode) {
    //   return Text(
    //     const JsonEncoder.withIndent('    ').convert(utxo),
    //   );
    // }
    return Column(
      children: [
        Row(
          children: [
            Text(
              "OUTPUT #$index",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).primaryColor),
            ),
            const Spacer(),
            Text(
              getPrettyAmount(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
        Text(
          utxo["keyImage"].toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String getPrettyAmount() =>
      ((utxo["amount"] / 1e12) as num).toStringAsFixed(4);
}