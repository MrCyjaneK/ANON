import 'dart:convert';
import 'dart:io';
import 'package:anon_wallet/channel/node_channel.dart';
import 'package:path/path.dart' as p;
import 'package:anon_wallet/channel/wallet_backup_restore_channel.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> isSocks5ProxyListening(String host, int port) async {
  try {
    final socket = await Socket.connect(host, port);
    socket.destroy();
    return true;
  } catch (e) {
    return false;
  }
}

Process? proc;
Future<void> runEmbeddedTor() async {
  final docs = await getApplicationDocumentsDirectory();
  const port = 42142;
  final proxy = await NodeChannel().getProxy();
  final ltpath = p.join(docs.absolute.path, "last-tor-port");
  if (!File(ltpath).existsSync()) {
    File(ltpath).createSync(recursive: true);
  }
  int? lastUsedPort = int.tryParse(File(ltpath).readAsStringSync()) ??
      int.tryParse(proxy.portTor);
  lastUsedPort ??= 9050;

  if (lastUsedPort != port) {
    File(ltpath).writeAsStringSync(lastUsedPort.toString());
    await NodeChannel()
        .setProxy(proxy.serverUrl, lastUsedPort.toString(), proxy.portI2p);
  }

  final node = await NodeChannel().getNodeFromPrefs();
  // node == null should be enough for offline wallet check. We don't want tor
  // there.
  if (node?.host?.endsWith(".i2p") == true &&
      node?.host != null &&
      node?.host != "") {
    print("We are connected to i2p (or not at all), ignoring tor config.");

    return;
  }
  final torBinPath = p.join(
      await BackUpRestoreChannel().getAndroidNativeLibraryDirectory(),
      "libKmpTor.so");
  print("torPath: $torBinPath");
  int portTor = int.tryParse(proxy.portTor) ?? lastUsedPort;
  if (portTor == 0 || portTor == port) {
    portTor = lastUsedPort;
  }
  final isProxyRunning = await isSocks5ProxyListening(proxy.serverUrl, portTor);
  if (isProxyRunning && proxy.portTor != "") {
    await NodeChannel()
        .setProxy("127.0.0.1", portTor.toString(), proxy.portI2p);
    return;
  }
  print("Starting embedded tor");
  print("app docs: $docs");
  await NodeChannel().setProxy("127.0.0.1", port.toString(), proxy.portI2p);
  final torrc = """
SocksPort $port
Log notice file ${p.join(docs.absolute.path, "tor.log")}
RunAsDaemon 0
DataDirectory ${p.join(docs.absolute.path, "tor-data")}
""";
  final torrcPath = p.join(docs.absolute.path, "torrc");
  File(torrcPath).writeAsStringSync(torrc);

  if (proc != null) {
    proc?.kill();
    await Future.delayed(const Duration(seconds: 1));
    proc?.kill(ProcessSignal.sigkill);
    await Future.delayed(const Duration(seconds: 1));
    final td = Directory(p.join(docs.absolute.path, "tor-data"));
    if (td.existsSync()) {
      td.deleteSync(recursive: true);
    }
    proc?.kill(ProcessSignal.sigkill);
    await Future.delayed(const Duration(seconds: 1));
  }
  proc = await Process.start(torBinPath, ["-f", torrcPath]);
  proc?.stdout.transform(utf8.decoder).forEach(print);
  proc?.stderr.transform(utf8.decoder).forEach(print);
}
