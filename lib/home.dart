import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;
import 'package:serial/app.dart';
import 'package:serial/tmp.dart';

class Home extends HookWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final title = useTextEditingController();
    final toPDF = useState(false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Tmp.clear();
                      showSnackBar('🧹 Cache cleared');
                    },
                    child: const Icon(Icons.clear),
                  ),
                ),
                const Gap(80),
                SizedBox(
                  child: TextField(
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
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
                      fontFeatures: [FontFeature.tabularFigures()],
                      fontSize: 200,
                    ),
                  ),
                ),
                const Text('PDF'),
                Switch(
                    value: toPDF.value,
                    onChanged: (_) => toPDF.value = !toPDF.value),
              ],
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
            showSnackBar('❌ Not contains http');
            return;
          }
          final images = await downloadImeges(url, counter);
          final t = title.text.isEmpty ? 'document' : title.text;
          if (toPDF.value) {
            final pdf = await createPDF(images, t);
            await OpenFile.open(pdf.path);
          } else {
            await putImages(images, t);
          }
          showSnackBar('✅ Done');
          await Tmp.clear();
          counter.value = 0;
          title.clear();
        },
      ),
    );
  }
}

Future<List<File>> downloadImeges(
    String url, ValueNotifier<int> counter) async {
  List<File> images = [];
  final extension = url.substring(url.lastIndexOf('.'));
  final beforeEx = url.substring(0, url.lastIndexOf('.'));

  for (var i = 1; i < 1000; i++) {
    final path = '${Tmp.path}/$i$extension';
    try {
      final u = '${beforeEx.substring(0, beforeEx.length - 1)}$i';
      await Dio().download('$u$extension', path);
    } on DioException catch (_) {
      break;
    }
    images.add(File(path));
    counter.value = i;
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
  final pdf = File('${Tmp.path}/$title.pdf');
  await pdf.writeAsBytes(await document.save());
  return pdf;
}

void showSnackBar(String text) {
  final context = naviKey.currentContext;
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    textAlign: TextAlign.center,
  )));
}
