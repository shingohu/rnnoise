import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pcm/pcm.dart';
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
  PCMPlayer player1 = PCMPlayer(sampleRateInHz: 48000);
  PCMPlayer player2 = PCMPlayer(sampleRateInHz: 48000);

  List<Uint8List> rnnoiseAudio = [];
  List<Uint8List> sourceAudio = [];

  @override
  void initState() {
    PCMRecorder.requestRecordPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RNNoise Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextButton(
                      onPressed: () {
                        print(RNNoise().getFrameSize());
                      },
                      child: Text("测试")),
                  TextButton(
                      onPressed: () async {
                        rnNoise.release();
                        rnNoise.create();
                        rnnoiseAudio.clear();
                        sourceAudio.clear();
                        await player1.stop();
                        await player2.stop();
                        PCMRecorder.start(
                          sampleRateInHz: 48000,
                          preFrameSize: 960,
                          onData: (data) {
                            if (data != null) {
                              int start = DateTime.now().millisecondsSinceEpoch;
                              Uint8List newData = rnNoise.process(data);
                              print(
                                  "耗时${DateTime.now().millisecondsSinceEpoch - start}");

                              sourceAudio.add(data);
                              rnnoiseAudio.add(newData);
                            } else {
                              rnNoise.release();
                            }
                          },
                        );
                      },
                      child: Text("开始录音")),
                  TextButton(
                      onPressed: () async {
                        print("结束录音");
                        await PCMRecorder.stop();
                      },
                      child: Text("结束录音")),
                  TextButton(
                      onPressed: () async {
                        player1.play();
                        sourceAudio.forEach((data) {
                          player1.feed(data);
                        });
                        sourceAudio.clear();
                      },
                      child: Text("播放原音")),
                  TextButton(
                      onPressed: () async {
                        player2.play();
                        rnnoiseAudio.forEach((data) {
                          player2.feed(data);
                        });
                        rnnoiseAudio.clear();
                      },
                      child: Text("播放降噪后")),
                  TextButton(
                      onPressed: () async {
                        readAndNoise();
                      },
                      child: Text("测试")),
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
    await player1.stop();
    uint8list ??=
        (await rootBundle.load("assets/48K.pcm")).buffer.asUint8List();
    List<int> list = [];
    for (int i = 0; i < uint8list!.length; i += 960) {
      Uint8List newData = rnNoise.process(uint8list!.sublist(i, i + 960));
      list.addAll(newData.toList());
    }
    player1.play();
    player1.feed(Uint8List.fromList(list));
  }
}
