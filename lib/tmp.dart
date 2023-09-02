import 'dart:io';

class Tmp {
  static Directory get get => Directory('${Directory.systemTemp.path}/serial');
  static String get path => get.path;
  static Future<void> clear() async {
    if (await get.exists()) await get.delete(recursive: true);
  }
}