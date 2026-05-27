import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rnnoise/rnnoise.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RNNoise rnNoise = RNNoise();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RNNoise降噪'),
        ),
        body: SingleChildScrollView(
          child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextButton(
                      onPressed: () async {
                        readAndNoise();
                      },
                      child: Text("48kPCM降噪处理")),
                ],
              )),
        ),
      ),
    );
  }

  Uint8List? uint8list;

  void readAndNoise() async {
    rnNoise.release();
    rnNoise.create();
    uint8list ??= (await rootBundle.load("assets/48K.pcm")).buffer.asUint8List();
    List<int> list = [];
    for (int i = 0; i < uint8list!.length; i += 960 * 4) {
      Stopwatch stopwatch = Stopwatch()..start();
      Uint8List newData = rnNoise.process(uint8list!.sublist(i, i + 960 * 4));
      list.addAll(newData.toList());
      stopwatch.stop();
      print("耗时${stopwatch.elapsedMilliseconds}");
    }
    File? file = await _createCacheAudioFile("48k_r");
    if (file != null) {
      file.writeAsBytes(list);
      print(file.path);
    }
  }

  ///创建PCM缓存
  Future<File?> _createCacheAudioFile(String prefix) async {
    DateTime time = DateTime.now();
    String fileName = prefix + "_" + time.millisecondsSinceEpoch.toString() + ".pcm";
    String? path = (await getApplicationDocumentsDirectory()).path + '/audio';
    File file = File(path + "/" + fileName);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }
}
