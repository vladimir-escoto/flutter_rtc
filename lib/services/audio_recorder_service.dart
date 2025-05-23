import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Result of an audio recording operation.
class AudioResult {
  final File file;
  final int durationSeconds;

  AudioResult({required this.file, required this.durationSeconds});
}

/// Basic audio recorder service using the [record] package.
class AudioRecorderService {
  final Record _record;
  final Future<bool> Function()? _checkPermissions;
  final Future<Directory> Function()? _getTempDir;


  /// Emits amplitude values from the underlying [Record] instance.
  ///
  /// The [interval] controls how frequently values are emitted. By default the
  /// record package sends updates every 300ms.
  Stream<Amplitude> onAmplitude({Duration interval = const Duration(milliseconds: 300)}) {
    // `Record` exposes a method `onAmplitude` which returns a stream of
    // [Amplitude] values. It is not a getter so we forward the call here.
    return _record.onAmplitude(interval: interval);
  }

  DateTime? _startTime;
  String? _filePath;

  AudioRecorderService({
    Record? record,
    Future<bool> Function()? checkPermissions,
    Future<Directory> Function()? tempDir,
  })  : _record = record ?? Record(),
        _checkPermissions = checkPermissions,
        _getTempDir = tempDir;

  Future<void> start({
    int sampleRate = 48000,
    int bitRate = 96000,
    AudioEncoder encoder = AudioEncoder.aac,
  }) async {
    final granted = await (_checkPermissions ?? _defaultCheckPermissions)();
    if (!granted) {
      throw Exception('Microphone or storage permission denied');
    }

    final dir = await (_getTempDir ?? getTemporaryDirectory)();
    final voiceDir = Directory('${dir.path}/voice');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = encoder == AudioEncoder.aac ? 'm4a' : 'opus';
    final path = '${voiceDir.path}/$timestamp.$extension';

    _filePath = path;
    _startTime = DateTime.now();

    await _record.start(
      path: path,
      encoder: encoder,
      bitRate: bitRate,
      samplingRate: sampleRate,
    );
  }

  Future<AudioResult> stop() async {
    final stoppedPath = await _record.stop();
    final path = stoppedPath ?? _filePath!;
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    return AudioResult(file: File(path), durationSeconds: duration);
  }

  Future<void> cancel() async {
    await _record.stop();
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static Future<bool> _defaultCheckPermissions() async {
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    return micStatus.isGranted && storageStatus.isGranted;
  }
}
