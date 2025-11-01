import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Lưu: { "123": [0.12, 0.03, ...], "456": [ ... ] }
class EmbeddingStorage {
  static const _fileName = 'embeddings.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$_fileName');
    if (!await f.exists()) {
      await f.writeAsString(jsonEncode({}));
    }
    return f;
  }

  Future<Map<int, List<double>>> loadAll() async {
    final f = await _file();
    final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final out = <int, List<double>>{};
    raw.forEach((k, v) {
      out[int.parse(k)] = (v as List).map((e) => (e as num).toDouble()).toList();
    });
    return out;
  }

  Future<void> saveOne(int studentId, List<double> emb) async {
    final f = await _file();
    final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    raw[studentId.toString()] = emb;
    await f.writeAsString(jsonEncode(raw));
  }

  Future<void> deleteOne(int studentId) async {
    final f = await _file();
    final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    raw.remove(studentId.toString());
    await f.writeAsString(jsonEncode(raw));
  }
}
