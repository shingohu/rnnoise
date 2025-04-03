import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UULog {
  static void enable(bool enable) {
    _enable = enable;
  }

  static bool _enable = kDebugMode;
  static _FileLog _fileLog = _FileLog._();

  UULog._();

  static String _threeDigits(int n) {
    if (n >= 100) return "${n}";
    if (n >= 10) return "0${n}";
    return "00${n}";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "${n}";
    return "0${n}";
  }

  static void d(Object msg) {
    if (_enable) {
      DateTime now = DateTime.now();
      String h = _twoDigits(now.hour);
      String min = _twoDigits(now.minute);
      String sec = _twoDigits(now.second);
      String ms = _threeDigits(now.millisecond);

      String time = "$h:$min:$sec.$ms";

      String line = "[UUSDK][$time]$msg";
      print(line);
      _fileLog.writeLog(info: line);
    }
  }

  ///写入bytes数据到本地文件
  static Future<void> writeBytes(List<int> bytes, {String? name}) async {
    return _fileLog.writeBytes(bytes, name: name);
  }

  ///本地日志文件列表
  static Future<List<String>> logFileList() async {
    String? path = await _fileLog.logFilePath;
    if (path != null) {
      var dir = Directory(path);
      return dir.listSync().map((e) {
        return e.path;
      }).toList()
        ..reversed.toList();
    }
    return List.empty();
  }

  static void showLogPage(BuildContext context) {
    Navigator.of(context).push(new MaterialPageRoute(builder: (ctx) {
      return _LogListPage();
    }));
  }
}

class _FileLog {
  _FileLog._();

  String? _logFilePath = null;
  File? _logFile;

  bool _isWriteLog = false;

  List<String> _logsBuffer = [];

  ///日志文件存储路径
  String? get logFilePath => _logFilePath;

  Future<String?> _logFilePathDir() async {
    if (_logFilePath != null) {
      return _logFilePath;
    }
    if (Platform.isAndroid) {
      _logFilePath = (await getExternalStorageDirectory())!.path + "/logs";
    } else if (Platform.isIOS) {
      _logFilePath = (await getApplicationDocumentsDirectory()).path + "/logs";
    }
    return _logFilePath;
  }

  void writeLog({required String info}) async {
    String msg = info + "\n";
    _logsBuffer.add(msg);
    if (!_isWriteLog) {
      _writeLog(_logsBuffer);
      _logsBuffer.clear();
    }
  }

  Future<void> _writeLog(List<String> msgs) async {
    _isWriteLog = true;
    DateTime time = DateTime.now();
    String name = DateFormat("yyyy-MM-dd").format(time) + ".txt";

    String? path = _logFilePath ?? await _logFilePathDir();

    if (path != null) {
      String pathWithName = path + "/" + name;
      if (_logFile == null || _logFile?.path != pathWithName) {
        _logFile = File(pathWithName);
      }

      if (!_logFile!.existsSync()) {
        _logFile!.createSync(recursive: true);
      }
      msgs.forEach((msg) {
        _logFile?.writeAsStringSync(msg,
            mode: FileMode.append, encoding: utf8, flush: true);
      });
      _isWriteLog = false;
    }
  }

  Future<void> writeBytes(List<int> bytes, {String? name}) async {
    String? path = _logFilePath ?? await _logFilePathDir();
    if (path != null) {
      String filename = name ?? "${DateTime.now().millisecondsSinceEpoch}";
      File _pcmFile = File(path + "/" + filename);
      if (_pcmFile.existsSync()) {
        _pcmFile.deleteSync();
      }
      _pcmFile.createSync(recursive: true);
      await _pcmFile.writeAsBytes(bytes, flush: true);
    }
  }
}

///本地日志列表页面
class _LogListPage extends StatefulWidget {
  const _LogListPage();

  @override
  State<_LogListPage> createState() => _LogListPageState();
}

class _LogListPageState extends State<_LogListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("本地日志列表")),
      body: FutureBuilder<List<String>>(
        builder: (ctx, data) {
          List<String> list = data.data ?? [];
          return ListView.builder(
            itemBuilder: (ctx, index) {
              return Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.white, width: 0.2))),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          OpenFilex.open(list[index]);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          list[index]
                              .substring(list[index].lastIndexOf("/") + 1),
                          style: TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        new File(list[index]).deleteSync();
                        setState(() {});
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.delete,
                            color: Colors.red,
                          )),
                    ),
                    GestureDetector(
                      onTap: () {
                        Share.shareXFiles([list[index]].map((e) {
                          return XFile(e);
                        }).toList());
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.share)),
                    )
                  ],
                ),
              );
            },
            itemCount: list.length,
          );
        },
        future: UULog.logFileList(),
      ),
    );
  }
}
