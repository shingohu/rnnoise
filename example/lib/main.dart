import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
                        rnNoise.create();
                        rnnoiseAudio.clear();
                        sourceAudio.clear();
                        await PCMPlayer.stop();
                        if (Platform.isIOS) {
                          await AudioManager.setPlayAndRecordSession(
                              defaultToSpeaker: true);
                        }
                        PCMRecorder.start(
                            sampleRateInHz: 48000,
                            onData: (data) {
                              if (data != null) {
                                Uint8List newData = rnNoise.process(data);
                                sourceAudio.add(data);
                                rnnoiseAudio.add(newData);
                              }
                            },
                            audioSource: AudioSource.MIC,
                            preFrameSize: 960 * 10);
                      },
                      child: Text("开始录音")),
                  TextButton(
                      onPressed: () async {
                        print("结束录音");
                        await PCMRecorder.stop();
                        Future.delayed(Duration(milliseconds: 100));
                        await AudioManager.abandonAudioFocus();
                        rnNoise.release();
                        print("播放录音");
                        sourceAudio.forEach((data) {
                          PCMPlayer.play(data, sampleRateInHz: 48000);
                        });

                        rnnoiseAudio.forEach((data) {
                          PCMPlayer.play(data, sampleRateInHz: 48000);
                        });
                        sourceAudio.clear();
                        rnnoiseAudio.clear();
                      },
                      child: Text("结束录音"))
                ],
              )),
        ),
      ),
    );
  }
}
