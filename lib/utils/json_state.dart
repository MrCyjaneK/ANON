// code made purerly for the background implementation to notify it about
// changes
import 'dart:io';

import 'package:path_provider/path_provider.dart';

String? _filePath;

Future<String> getStatsFilePath() async {
  if (_filePath != null) return _filePath!;
  final appdoc = (await getApplicationDocumentsDirectory());
  _filePath = "${appdoc.absolute.path}/appstate.json";
  return _filePath!;
}

Future<bool> getStatsExist() async {
  final f = File(await getStatsFilePath());
  return f.existsSync();
}

Future<String> getStats() async {
  final f = File(await getStatsFilePath());
  if (!f.existsSync()) {
    f.createSync();
    return '';
  }
  var body = f.readAsStringSync();
  return body;
}

Future<void> setStats(String stats) async {
  final f = File(await getStatsFilePath());
  f.writeAsStringSync(stats);
}
