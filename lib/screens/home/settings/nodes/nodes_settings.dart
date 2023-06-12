import 'package:anon_wallet/channel/node_channel.dart';
import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/screens/onboard/onboard_state.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:anon_wallet/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NodesSettingsScreens extends ConsumerStatefulWidget {
  const NodesSettingsScreens({Key? key}) : super(key: key);

  @override
  ConsumerState<NodesSettingsScreens> createState() => _NodesSettingsScreensState();
}

final _nodesListProvider = FutureProvider<List<Node>>((ref) => NodeChannel().getAllNodes());

class _NodesSettingsScreensState extends ConsumerState<NodesSettingsScreens> {
  @override
  Widget build(BuildContext context) {
    var asyncNodes = ref.watch(_nodesListProvider);
    List<Node> nodes = asyncNodes.asData?.value ?? [];
    bool isLoading = asyncNodes.isLoading;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(_nodesListProvider);
          return Future.value();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text("Nodes"),
              actions: [
                TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          barrierColor: barrierColor,
                          builder: (context) {
                            return const SizedBox(
                              child: Scaffold(
                                body: RemoteNodeAddSheet(),
                              ),
                            );
                          }).then((value) => ref.refresh(_nodesListProvider));
                    },
                    child: const Text("Add Node"))
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Opacity(
                  opacity: isLoading ? 1 : 0,
                  child: const LinearProgressIndicator(
                    minHeight: 1,
                  ),
                ),
              ),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              return Wrap(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    child: Card(
                      color: Colors.grey[900]?.withOpacity(0.9),
                      child: Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: ListTile(
                          onTap: () {
                            showDialog(
                                context: context,
                                barrierColor: barrierColor,
                                builder: (context) {
                                  return NodeDetails(nodes[index]);
                                }).then((value) => ref.refresh(_nodesListProvider));
                          },
                          title: Text("${nodes[index].host}", maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Consumer(
                            builder: (context, ref, c) {
                              int activeNodeDaemonHeight = ref.watch(walletNodeDaemonHeight);
                              int activeHeight = (activeNodeDaemonHeight > nodes[index].height)
                                  ? activeNodeDaemonHeight
                                  : nodes[index].height;
                              return Text(nodes[index].isActive == true ? "Height: $activeHeight" : "Inactive",
                                  maxLines: 1, overflow: TextOverflow.ellipsis);
                            },
                          ),
                          trailing: nodes[index].isActive == true
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.network_check, color: Colors.green),
                                    const Padding(padding: EdgeInsets.all(4)),
                                    Text("Active", style: Theme.of(context).textTheme.labelSmall)
                                  ],
                                )
                              : IconButton(
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      barrierColor: barrierColor,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                          content: const Text("Do you want to remove this node ?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Cancel")),
                                            TextButton(
                                                onPressed: () async {
                                                  try {
                                                    await NodeChannel().removeNode(nodes[index]);
                                                    ref.refresh(_nodesListProvider);
                                                  } catch (e) {
                                                    ref.refresh(_nodesListProvider);
                                                    print(e);
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Delete")),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.delete)),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }, childCount: nodes.length))
          ],
        ),
      ),
    );
  }
}

class NodeDetails extends ConsumerStatefulWidget {
  final Node node;

  const NodeDetails(this.node, {Key? key}) : super(key: key);

  @override
  ConsumerState<NodeDetails> createState() => _NodeDetailsState();
}

class _NodeDetailsState extends ConsumerState<NodeDetails> {
  Node? node;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        node = widget.node;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.only(top: 2, left: 12, right: 12, bottom: 6),
      content: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 344,
          child: Column(
            children: [
              AnimatedOpacity(
                opacity: loading ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: const LinearProgressIndicator(
                  minHeight: 1,
                ),
              ),
              AnimatedOpacity(
                opacity: error != null ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  width: double.infinity,
                  color: Colors.red,
                  child:
                      Text("$error", style: Theme.of(context).textTheme.subtitle2?.copyWith(fontSize: 13), maxLines: 1),
                ),
              ),
              ListTile(
                title: Text("Host"),
                subtitle: Text("${node?.host}"),
              ),
              const Divider(color: Colors.white70),
              ListTile(
                title: const Text("Height"),
                trailing: Text("${node?.height}"),
              ),
              const Divider(color: Colors.white70),
              ListTile(
                title: const Text("Port"),
                trailing: Text("${widget.node.port}"),
              ),
              const Divider(color: Colors.white70),
              ListTile(
                title: const Text("Version"),
                trailing: Text("${node?.majorVersion}"),
              ),
              const Divider(color: Colors.white70),
            ],
          )),
      actions: [
        TextButton(
            onPressed: !loading
                ? () {
                    testRpc();
                  }
                : null,
            child: const Text("Test Network")),
        TextButton(
            onPressed: !loading
                ? () {
                    if (node != null) {
                      setAsCurrentNode(node!).then((value) => Navigator.pop(context));
                    }
                  }
                : null,
            child: const Text("Set Node")),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"))
      ],
    );
  }

  void testRpc() async {
    Node widgetNode = widget.node;
    try {
      setState(() {
        loading = true;
        error = null;
      });
      Node? refreshedNode =
          await NodeChannel().testRpc(widgetNode.host, widgetNode.port ?? 80, widgetNode.username, widgetNode.password);
      if (refreshedNode != null) {
        setState(() {
          loading = false;
          node = refreshedNode;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = "${e}";
      });
      print(e);
    }
  }

  Future setAsCurrentNode(Node node) async {
    try {
      setState(() {
        error = null;
        loading = true;
      });
      await NodeChannel().setCurrentNode(node);
      setState(() {
        loading = false;
        error = null;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      setState(() {
        loading = false;
        error = "${e}";
      });
    }
  }
}

final nodeRemoteConnectionProvider = StateNotifierProvider<ConnectToNodeState, Node?>((ref) {
  return ConnectToNodeState(ref);
});

class RemoteNodeAddSheet extends HookConsumerWidget {
  const RemoteNodeAddSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextEditingController nodeTextController = useTextEditingController(text: "");
    TextEditingController userNameTextController = useTextEditingController(text: "");
    TextEditingController passWordTextController = useTextEditingController(text: "");
    var isLoading = useState(false);
    var nodeStatus = useState<String?>(null);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          title: const Text("Add Node"),
          centerTitle: true,
          bottom: isLoading.value
              ? const PreferredSize(preferredSize: Size.fromHeight(1), child: LinearProgressIndicator(minHeight: 1))
              : null,
        ),
        SliverToBoxAdapter(
          child: ListTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text("NODE", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ),
            subtitle: TextField(
              controller: nodeTextController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1),
                ),
                helperText: nodeStatus.value,
                helperMaxLines: 3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'http://address.onion:port',
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ListTile(
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text("USERNAME", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ),
            subtitle: TextField(
              controller: userNameTextController,
              textInputAction: TextInputAction.next,
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
              child: Text("PASSWORD", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ),
            subtitle: TextField(
              controller: passWordTextController,
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
                ElevatedButton(
                  onPressed: () async {
                    await connect(nodeTextController.text, userNameTextController.text, passWordTextController.text,
                        isLoading, nodeStatus, context,ref);
                    await Future.delayed(Duration(milliseconds: 200));
                    ref.refresh(_nodesListProvider);
                  },
                  style: Theme.of(context)
                      .elevatedButtonTheme
                      .style
                      ?.copyWith(backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white)),
                  child: const Text("Add Node"),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Future connect(String host, String username, String password, ValueNotifier<bool> isLoading,
      ValueNotifier<String?> nodeStatus, BuildContext context,WidgetRef ref) async {
    int port = 38081;
    Uri uri = Uri.parse(host);
    if (uri.hasPort) {
      port = uri.port;
    }
    try {
      isLoading.value = true;
      Node? node = await NodeChannel().addNode(uri.host, port, username, password);
      if (node != null) {
        nodeStatus.value = "Connected to ${node.host}\nHeight : ${node.height}";
      }
      isLoading.value = false;
      await Future.delayed(const Duration(milliseconds: 600));
      ref.refresh(_nodesListProvider);
      Navigator.pop(context);
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${e.message}")));
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }
}
