// code made purerly for the background implementation to notify it about
// changes

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

String? _filePath;

Future<String> getStatsFilePath() async {
  if (_filePath != null) return _filePath!;
  final appdoc = (await getApplicationDocumentsDirectory());
  _filePath = "${appdoc.absolute.path}/appstate.json";
  return _filePath!;
}

Future<Map<String, dynamic>> getStats() async {
  final f = File(await getStatsFilePath());
  if (!f.existsSync()) {
    return {
      "updated": DateTime.now().toIso8601String(),
      "height": 0,
    };
  }
  final body = f.readAsStringSync();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<void> setStats(Map<String, dynamic> stats) async {
  final f = File(await getStatsFilePath());
  f.writeAsStringSync(jsonEncode(stats));
}
