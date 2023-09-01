import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;

class Home extends HookWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final title = useTextEditingController();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    child: TextField(
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                      controller: title,
                      maxLines: null,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                  FittedBox(
                    child: Text(
                      counter.value.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 200,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await Tmp.clear();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(snackBar('✅ Cache cleared'));
                    },
                    child: const Icon(Icons.clear),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        child: const Icon(Icons.download),
        onPressed: () async {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          final url = data?.text ?? '';
          if (!url.contains('http')) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(snackBar('❌ Not contains http'));
            return;
          }
          final images = await downloadImeges(url, counter);
          final pdf = await createPDF(images, title);
          await OpenFile.open(pdf.path);
          await Tmp.clear();
          counter.value = 0;
          title.clear();
        },
      ),
    );
  }
}

Future<List<p.MemoryImage>> downloadImeges(
    String url, ValueNotifier<int> counter) async {
  List<p.MemoryImage> images = [];
  final baseUrl = url.substring(0, url.lastIndexOf('/'));
  final extension = url.substring(url.lastIndexOf('.'));

  for (var i = 1; i < 1000; i++) {
    final path = '${Tmp.path}/$i$extension';
    try {
      await Dio().download('$baseUrl/$i$extension', path);
    } on DioException catch (_) {
      break;
    }
    images.add(p.MemoryImage(await File(path).readAsBytes()));
    counter.value = i;
  }
  return images;
}

Future<File> createPDF(
    List<p.MemoryImage> images, TextEditingController title) async {
  final document = p.Document();
  for (var image in images) {
    document.addPage(p.Page(
        pageFormat: PdfPageFormat.undefined,
        build: (_) => p.Center(child: p.Image(image))));
  }
  if (title.text.isEmpty) title.text = 'document';
  final pdf = File('${Tmp.path}/${title.text}.pdf');
  await pdf.writeAsBytes(await document.save());
  return pdf;
}

SnackBar snackBar(String text) => SnackBar(
        content: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      textAlign: TextAlign.center,
    ));

class Tmp {
  static Directory get get => Directory('${Directory.systemTemp.path}/serial');
  static String get path => get.path;
  static Future<void> clear() async {
    if (await get.exists()) await get.delete(recursive: true);
  }
}
