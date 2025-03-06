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
  final Pointer<Void> _nullptr = Pointer.fromAddress(0);

  Pointer<Void>? _handle;

  bool get _hasInit => _handle != null && _handle != _nullptr;

  ///每次处理的帧数
  ///模型支持是48k采样率，所以每次处理480帧,但是模型每次需要输入2包数据,所有每次的长度是960帧
  int getFrameSize() {
    return _bindings.get_frame_size();
  }

  void create() {
    if (!_hasInit) {
      _handle = _bindings.create();
    }
  }

  Uint8List process(Uint8List data) {
    if (!_hasInit) {
      return data;
    }
    int frameSize = getFrameSize();

    if (data.length < frameSize) {
      return data;
    }
    int byteLength = data.length;
    data = data.sublist(0, (byteLength ~/ frameSize) * frameSize);

    return ffi.using((arena) {
      Float32List input = _bytesToFloat(data);
      int floatLength = input.length;
      final inputPtr = arena<Float>(floatLength);
      inputPtr.asTypedList(floatLength).setAll(0, input);

      final outPtr = arena<Float>(floatLength);
      _bindings.process_frame(_handle!, outPtr, inputPtr, floatLength);
      data = _floatToBytes(outPtr.asTypedList(floatLength));
      return data;
    });
  }

  ///释放
  void release() {
    if (_hasInit) {
      _bindings.destroy(_handle!);
      _handle = null;
    }
  }

  static Float32List _bytesToFloat(Uint8List bytes) {
    Float32List float = Float32List(bytes.length ~/ 2);
    for (int i = 0; i < float.length; i++) {
      if ((bytes[i * 2 + 1] & 0x80) != 0) {
        float[i] =
            (-32768 + ((bytes[i * 2 + 1] & 0x7f) << 8) | (bytes[i * 2] & 0xff))
                .toDouble();
      } else {
        float[i] = (((bytes[i * 2 + 1] << 8) & 0xff00) | (bytes[i * 2] & 0xff))
            .toDouble();
      }
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
