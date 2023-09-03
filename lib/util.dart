import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;

Future<List<File>> downloadImeges(
    String url, void Function(int i) perDownloaded) async {
  List<File> images = [];
  final extension = url.substring(url.lastIndexOf('.'));
  final beforeEx = url.substring(0, url.lastIndexOf('.'));

  for (var i = 1; i < 1000; i++) {
    final path = '${tmp.path}/$i$extension';
    try {
      final u = '${beforeEx.substring(0, beforeEx.length - 1)}$i';
      await Dio().download('$u$extension', path);
    } on DioException catch (_) {
      break;
    }
    perDownloaded(i);
    images.add(File(path));
  }
  return images;
}

Future<void> putImages(List<File> images, String title) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory('${documents.path}/$title');
  if (!await directory.exists()) await directory.create();
  for (final (i, image) in images.indexed) {
    await image.copy('${directory.path}/image_$i.jpg');
  }
}

Future<File> createPDF(List<File> images, String title) async {
  final document = p.Document();
  for (var image in images) {
    document.addPage(p.Page(
        pageFormat: PdfPageFormat.undefined,
        build: (_) =>
            p.Center(child: p.Image(p.MemoryImage(image.readAsBytesSync())))));
  }
  final pdf = File('${tmp.path}/$title.pdf');
  await pdf.writeAsBytes(await document.save());
  return pdf;
}

Directory get tmp => Directory('${Directory.systemTemp.path}/serial');

Future<void> clearTmp() async {
  if (await tmp.exists()) await tmp.delete(recursive: true);
}
