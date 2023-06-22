import 'package:anon_wallet/channel/node_channel.dart';
import 'package:anon_wallet/channel/wallet_events_channel.dart';
import 'package:anon_wallet/models/node.dart';
import 'package:anon_wallet/state/wallet_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum NodeConnectionState { connected, disconnected }

final connectedNode = StateProvider<Node?>((ref) => null);
final nodeConnectionState =
    StreamProvider((ref) => WalletEventsChannel().nodeStream());
final nodeFromPrefs =
    FutureProvider<Node?>((ref) => NodeChannel().getNodeFromPrefs());

final nodeErrorState = StateProvider<String?>((ref) {
  Node? node = ref.watch(nodeConnectionState).value;
  if (node != null) {
    if (node.connectionError.isNotEmpty) {
      return node.connectionError;
    } else if (node.responseCode <= 200) {
      return null;
    } else {
      return "Node not connected";
    }
  } else {
    return "Node not connected";
  }
});

final connectingToNodeStateProvider = Provider<bool>((ref) {
  var connectionState = ref.watch(nodeConnectionState).value;
  if (connectionState != null) {
    return connectionState.isConnecting();
  } else {
    return false;
  }
});

final syncProgressStateProvider = Provider<Map<String, num>?>((ref) {
  var connectionState = ref.watch(nodeConnectionState).value;
  ref.watch(walletStateStreamProvider).value;
  if (connectionState != null) {
    num blockChainHeight = connectionState.blockchainHeight;
    if (connectionState.syncBlock != 0 && blockChainHeight != 0) {
      num remaining = (blockChainHeight - connectionState.syncBlock);
      num progress = connectionState.syncBlock / blockChainHeight;
      if (progress >= 1 || remaining < 10) {
        return null;
      }
      return {
        "remaining": connectionState.remainingBlocks,
        "progress": connectionState.syncPercentage
      };
    } else {
      return null;
    }
  } else {
    return null;
  }
});
final nodeSyncProgress = StateProvider<NodeConnectionState>(
    (ref) => NodeConnectionState.disconnected);
