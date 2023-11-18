import 'package:flutter/material.dart';

class PolySeedWidget extends StatefulWidget {
  final List<String> seedWords;
  final bool heroEnabled;

  const PolySeedWidget(
      {super.key, required this.seedWords, required this.heroEnabled});

  @override
  State<PolySeedWidget> createState() => _PolySeedWidgetState();
}

class _PolySeedWidgetState extends State<PolySeedWidget> {
  List<String> seeds = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      seeds = widget.seedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (widget.heroEnabled)
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
              "POLYSEED MNEMONIC",
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontSize: 22, color: Colors.white),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('${index + 1}.'),
                    SizedBox(
                      width: 80,
                      child: Text(
                        seeds[index],
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontSize: 14),
                        textAlign: TextAlign.start,
                      ),
                    )
                  ],
                ),
              );
            },
            childCount: seeds.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 8,
            childAspectRatio: 4,
          ),
        )
      ],
    );
  }
}
