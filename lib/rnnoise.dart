import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;

import 'rnnoise_bindings_generated.dart';

const String _libName = 'rnnoise';

/// The dynamic library in which the symbols for [RnnoiseBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final RnnoiseBindings _bindings = RnnoiseBindings(_dylib);

class RNNoise {
  final Pointer<DenoiseState> _nullptr = Pointer.fromAddress(0);

  Pointer<DenoiseState>? _handle;

  bool get _hasInit => _handle != null && _handle != _nullptr;

  ///每次处理的帧数
  ///模型支持是48k采样率，所以每次处理480帧,16位PCM,需要960个字节
  int getFrameSize() {
    return _bindings.rnnoise_get_frame_size();
  }

  void create() {
    if (!_hasInit) {
      ffi.using((arena) {
        Pointer<RNNModel> model = nullptr;
        _handle = _bindings.rnnoise_create(model);
      });
    }
  }

  Float32List process(Float32List data) {
    return ffi.using((arena) {
      Float32List input = data;
      int floatLength = input.length;
      final inputPtr = arena<Float>(floatLength);
      inputPtr.asTypedList(floatLength).setAll(0, input);

      final outPtr = arena<Float>(floatLength);
      _bindings.rnnoise_process_frame(_handle!, outPtr, inputPtr);
      return outPtr.asTypedList(floatLength);
    });
  }

  Uint8List process16BitPCM(Uint8List data) {
    int size = getFrameSize();
    int processSize = 0;
    List<int> processList = [];
    for (int i = 0; i < data.length; i += size * 2) {
      processSize += size * 2;
      Float32List float = _bytesToFloat(data.sublist(i, i + size * 2));
      Float32List newData = process(float);
      Uint8List newBytes = _floatToBytes(newData);
      processList.addAll(newBytes);
    }

    ///不能处理的部分
    processList.addAll(data.sublist(processSize));
    return Uint8List.fromList(processList);
  }

  ///释放
  void release() {
    if (_hasInit) {
      _bindings.rnnoise_destroy(_handle!);
      _handle = null;
    }
  }

  static Float32List _bytesToFloat(Uint8List bytes) {
    Float32List float = Float32List(bytes.length ~/ 2);
    for (int i = 0; i < float.length; i++) {
      int x;
      if ((bytes[i * 2 + 1] & 0x80) != 0) {
        x = (-32768 + ((bytes[i * 2 + 1] & 0x7f) << 8) | (bytes[i * 2] & 0xff));
      } else {
        x = (((bytes[i * 2 + 1] << 8) & 0xff00) | (bytes[i * 2] & 0xff));
      }
      float[i] = x.toDouble();
    }
    return float;
  }

  static Uint8List _floatToBytes(Float32List input) {
    Uint8List bytes = Uint8List(input.length * 2);
    for (int i = 0; i < input.length; i++) {
      int x = input[i].toInt();
      bytes[i * 2] = (x & 0x00FF);
      bytes[i * 2 + 1] = ((x & 0xFF00) >> 8);
    }
    return bytes;
  }
}
