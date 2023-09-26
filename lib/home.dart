import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:open_file/open_file.dart';

import 'package:serial/main.dart';
import 'package:serial/util.dart';

class Home extends HookWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    final counter = useState(0);
    final title = useTextEditingController();
    final toPDF = useState(true);

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
                      await clearTmp();
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
          final images = await downloadImeges(url, (i) => counter.value = i);
          final t = title.text.isEmpty ? 'document' : title.text;
          if (toPDF.value) {
            final pdf = await createPDF(images, t);
            await OpenFile.open(pdf.path);
          } else {
            await putImages(images, t);
          }
          showSnackBar('✅ Done');
          await clearTmp();
          counter.value = 0;
          title.clear();
        },
      ),
    );
  }
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
