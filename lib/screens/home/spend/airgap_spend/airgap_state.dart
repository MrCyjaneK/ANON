import 'package:anon_wallet/channel/wallet_channel.dart';
import 'package:anon_wallet/plugins/camera_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final exportWalletOutProvider =
    FutureProvider<String>((ref) => WalletChannel().exportOutputs(false));

final exportWalletKeyImagesProvider =
    FutureProvider<String>((ref) => WalletChannel().exportKeyImages());

class URGenerateRequest {
  //File path to the file to be encoded
  final String fpath;
  //UR Type of the file to be encoded
  final UrType type;

  URGenerateRequest({required this.fpath, required this.type});
}

final generateURQR = FutureProvider.family<List<String>, URGenerateRequest>(
    (ref, request) async {
  var items = await anonCameraMethodChannel.invokeListMethod<String>(
      "createUR", {"fpath": request.fpath, "type": request.type.type});
  return items ?? List<String>.empty();
});
