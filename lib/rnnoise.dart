import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'rnnoise_bindings_generated.dart';

const String _libName = 'rnnoise';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.operatingSystem == "ohos") {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final RnnoiseBindings _bindings = RnnoiseBindings(_dylib);

class RNNoise {
  final Pointer<DenoiseState> _nullptr = Pointer.fromAddress(0);
  Pointer<DenoiseState>? _handle;

  /// Pre-allocated native buffers, reused across calls to avoid per-frame alloc.
  Pointer<Int16>? _inPtr;
  Pointer<Int16>? _outPtr;
  int _bufSamples = 0;

  bool get _hasInit => _handle != null && _handle != _nullptr;

  int getFrameSize() {
    return _bindings.rnnoise_get_frame_size();
  }

  void init() {
    if (!_hasInit) {
      Pointer<RNNModel> model = nullptr;
      _handle = _bindings.rnnoise_create(model);
    }
  }

  void _ensureBuffer(int totalSamples) {
    if (totalSamples == _bufSamples && _inPtr != null) {
      return;
    }
    if (_inPtr != null) {
      malloc.free(_inPtr!);
      malloc.free(_outPtr!);
    }
    _inPtr = malloc<Int16>(totalSamples);
    _outPtr = malloc<Int16>(totalSamples);
    _bufSamples = totalSamples;
  }

  void freeBuffer() {
    if (_inPtr != null) {
      malloc.free(_inPtr!);
      malloc.free(_outPtr!);
      _inPtr = null;
      _outPtr = null;
      _bufSamples = 0;
    }
  }

  /// Denoise 16-bit PCM data.
  ///
  /// [data] contains raw 16-bit mono PCM bytes. Input length should be a
  /// multiple of frameSize*2 bytes (480 samples = 960 bytes per frame).
  /// Returns denoised PCM bytes of the same length.
  Uint8List process(Uint8List data) {
    if (!_hasInit) {
      return data;
    }
    int frameSize = getFrameSize(); // 480 samples per frame
    int totalSamples = data.lengthInBytes ~/ 2;
    int numFrames = totalSamples ~/ frameSize;

    if (numFrames == 0) return data;

    int processedSamples = numFrames * frameSize;
    int processedBytes = processedSamples * 2;

    _ensureBuffer(processedSamples);

    // Bulk copy input bytes to native memory (single copy, not per-frame)
    _inPtr!.cast<Uint8>().asTypedList(processedBytes).setAll(0, data.sublist(0, processedBytes));

    // Process each frame using native int16 wrapper (no float conversion in Dart)
    for (int i = 0; i < numFrames; i++) {
      int offset = i * frameSize;
      _bindings.rnnoise_process_frame_int16(
        _handle!,
        _outPtr! + offset,
        _inPtr! + offset,
      );
    }

    // Build result: processed data + unprocessed remainder
    Uint8List result = Uint8List(data.length);
    result.setAll(0, _outPtr!.cast<Uint8>().asTypedList(processedBytes));
    for (int i = processedBytes; i < data.length; i++) {
      result[i] = data[i];
    }

    return result;
  }

  void release() {
    if (_hasInit) {
      _bindings.rnnoise_destroy(_handle!);
      _handle = null;
    }
    freeBuffer();
  }
}
