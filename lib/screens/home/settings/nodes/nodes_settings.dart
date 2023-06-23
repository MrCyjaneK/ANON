import 'package:anon_wallet/channel/node_channel.dart';
import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/screens/home/settings/proxy_settings.dart';
import 'package:anon_wallet/screens/home/settings/settings_state.dart';
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
  ConsumerState<NodesSettingsScreens> createState() =>
      _NodesSettingsScreensState();
}

final _nodesListProvider =
    FutureProvider<List<Node>>((ref) => NodeChannel().getAllNodes());

class _NodesSettingsScreensState extends ConsumerState<NodesSettingsScreens> {
  Node? _settingCurrentNode;

  @override
  Widget build(BuildContext context) {
    var asyncNodes = ref.watch(_nodesListProvider);
    List<Node> nodes = asyncNodes.asData?.value ?? [];
    bool isLoading = asyncNodes.isLoading;
    Node? connectedNode =
        nodes.where((element) => element.isActive == true).first;
    bool isConnected = ref.watch(connectionStatus);
    nodes = nodes.where((element) => element.isActive == false).toList();

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
                    onPressed: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RemoteNodeAddSheet(),
                          ));
                      ref.refresh(_nodesListProvider);
                    },
                    child: const Text("Add Node"))
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Opacity(
                  opacity: (isLoading || _settingCurrentNode != null) ? 1 : 0,
                  child: const LinearProgressIndicator(
                    minHeight: 1,
                  ),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.all(12)),
            SliverAppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 88,
              flexibleSpace: Card(
                  elevation: 0,
                  borderOnForeground: true,
                  shadowColor: isConnected
                      ? Colors.green.withOpacity(0.4)
                      : Colors.red.withOpacity(0.4),
                  surfaceTintColor: Colors.white,
                  color: Colors.grey[900],
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: _settingCurrentNode != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Switching node",
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text("${_settingCurrentNode?.host}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis ,
                                      style:
                                          Theme.of(context).textTheme.bodySmall),
                                )
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Padding(padding: EdgeInsets.all(4)),
                              ListTile(
                                onLongPress: () {
                                  showDialog(
                                          context: context,
                                          barrierColor: barrierColor,
                                          builder: (context) {
                                            return NodeDetails(connectedNode);
                                          })
                                      .then((value) =>
                                          ref.refresh(_nodesListProvider));
                                },
                                title: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text("${connectedNode.host}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                ),
                                subtitle: Consumer(
                                  builder: (context, ref, c) {
                                    int activeNodeDaemonHeight =
                                        ref.watch(walletNodeDaemonHeight);
                                    int activeHeight = (activeNodeDaemonHeight >
                                            connectedNode.height)
                                        ? activeNodeDaemonHeight
                                        : connectedNode.height;
                                    return Text(
                                        connectedNode.isActive == true
                                            ? "Daemon Height: $activeHeight"
                                            : "Inactive",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis);
                                  },
                                ),
                                trailing: Container(
                                  height: 12,
                                  width: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              const Padding(padding: EdgeInsets.all(4)),
                            ],
                          ),
                  )),
            ),
            const SliverPadding(padding: EdgeInsets.all(8)),
            const SliverToBoxAdapter(
              child: Divider(),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Text("Available Nodes"),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(),
            ),
            SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              return Wrap(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    child: Card(
                      color: Colors.grey[900]?.withOpacity(0.6),
                      child: Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: ListTile(
                          onTap: () {
                            if (nodes[index].isActive != true) {
                              setAsCurrentNode(nodes[index]);
                            }
                          },
                          onLongPress: () {
                            showDialog(
                                    context: context,
                                    barrierColor: barrierColor,
                                    builder: (context) {
                                      return NodeDetails(nodes[index]);
                                    })
                                .then(
                                    (value) => ref.refresh(_nodesListProvider));
                          },
                          title: Text("${nodes[index].host}",
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Consumer(
                            builder: (context, ref, c) {
                              int activeNodeDaemonHeight =
                                  ref.watch(walletNodeDaemonHeight);
                              int activeHeight =
                                  (activeNodeDaemonHeight > nodes[index].height)
                                      ? activeNodeDaemonHeight
                                      : nodes[index].height;
                              return Text(
                                  nodes[index].isActive == true
                                      ? "Height: $activeHeight"
                                      : "Inactive",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis);
                            },
                          ),
                          trailing: nodes[index].isActive == true
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 12,
                                      width: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isConnected
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.all(4)),
                                    Text("Active",
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall)
                                  ],
                                )
                              : IconButton(
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      barrierColor: barrierColor,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          content: const Text(
                                              "Do you want to remove this node ?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Cancel")),
                                            TextButton(
                                                onPressed: () async {
                                                  try {
                                                    await NodeChannel()
                                                        .removeNode(
                                                            nodes[index]);
                                                    ref.refresh(
                                                        _nodesListProvider);
                                                  } catch (e) {
                                                    ref.refresh(
                                                        _nodesListProvider);
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

  Future setAsCurrentNode(Node node) async {
    try {
      setState(() {
        _settingCurrentNode = node;
      });
      await NodeChannel().setCurrentNode(node);
      setState(() {
        _settingCurrentNode = null;
      });
      ref.refresh(_nodesListProvider);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      setState(() {
        _settingCurrentNode = null;
      });
    }
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
      testRpc();
      setState(() {
        node = widget.node;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      contentPadding:
          const EdgeInsets.only(top: 2, left: 12, right: 12, bottom: 6),
      content: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 360,
          child: SingleChildScrollView(
            child: Column(
              children: [
                AnimatedOpacity(
                  opacity: loading ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const LinearProgressIndicator(
                    minHeight: 1,
                  ),
                ),
                AnimatedContainer(
                  height: error != null ? 80 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    width: double.infinity,
                    child: Text("$error",
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontSize: 13, color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3),
                  ),
                ),
                ListTile(
                  title: const Text("Host"),
                  subtitle: Text("${node?.host}"),
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
                ListTile(
                  title: const Text("Username"),
                  trailing: Text("${node?.username} "),
                ),
                const Divider(color: Colors.white70),
                ListTile(
                  title: const Text("Password"),
                  trailing: Text("${node?.password} "),
                ),
              ],
            ),
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
                      setAsCurrentNode(node!)
                          .then((value) => Navigator.pop(context));
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
      Node? refreshedNode = await NodeChannel().testRpc(widgetNode.host,
          widgetNode.port ?? 80, widgetNode.username, widgetNode.password);
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

final nodeRemoteConnectionProvider =
    StateNotifierProvider<ConnectToNodeState, Node?>((ref) {
  return ConnectToNodeState(ref);
});

class RemoteNodeAddSheet extends HookConsumerWidget {
  const RemoteNodeAddSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextEditingController nodeTextController =
        useTextEditingController(text: "");
    TextEditingController userNameTextController =
        useTextEditingController(text: "");
    TextEditingController passWordTextController =
        useTextEditingController(text: "");
    var isLoading = useState(false);
    var nodeStatus = useState<String?>(null);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: true,
              title: const Text("Add Node"),
              centerTitle: false,
              bottom: isLoading.value
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(1),
                      child: LinearProgressIndicator(minHeight: 1))
                  : null,
            ),
            SliverToBoxAdapter(
              child: ListTile(
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text("NODE",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                ),
                subtitle: TextField(
                  controller: nodeTextController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1),
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
                  child: Text("USERNAME",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                ),
                subtitle: TextField(
                  controller: userNameTextController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1),
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
                  controller: passWordTextController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 1),
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
                padding: const EdgeInsets.only(top: 18),
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
                    padding: const EdgeInsets.only(top: 8),
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
              fillOverscroll: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(width: 1.0, color: Colors.white),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  width: 12, color: Colors.white),
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 6)),
                      onPressed: () async {
                        await connect(
                            nodeTextController.text,
                            userNameTextController.text,
                            passWordTextController.text,
                            isLoading,
                            nodeStatus,
                            context,
                            ref);
                        await Future.delayed(const Duration(milliseconds: 200));
                        ref.refresh(_nodesListProvider);
                      },
                      child: Text("Connect",
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future connect(
      String host,
      String username,
      String password,
      ValueNotifier<bool> isLoading,
      ValueNotifier<String?> nodeStatus,
      BuildContext context,
      WidgetRef ref) async {
    int port = 38081;
    Uri uri = Uri.parse(host);
    if (uri.hasPort) {
      port = uri.port;
    }
    try {
      isLoading.value = true;
      Node? node =
          await NodeChannel().addNode(uri.host, port, username, password);
      if (node != null) {
        nodeStatus.value = "Connected to ${node.host}\nHeight : ${node.height}";
      }
      isLoading.value = false;
      await Future.delayed(const Duration(milliseconds: 600));
      ref.refresh(_nodesListProvider);
      Navigator.pop(context);
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("${e.message}")));
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }
}
