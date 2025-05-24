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
  final AudioRecorder _record;
  final Future<bool> Function()? _checkPermissions;
  final Future<Directory> Function()? _getTempDir;

  Stream<Amplitude> onAmplitude(
      {Duration interval = const Duration(milliseconds: 300)}) {
    return _record.onAmplitudeChanged(interval);
  }

  DateTime? _startTime;
  String? _filePath;
  AudioRecorderService({
    AudioRecorder? record,
    Future<bool> Function()? checkPermissions,
    Future<Directory> Function()? tempDir,
  })
      : _record = record ?? AudioRecorder(),
        _checkPermissions = checkPermissions,
        _getTempDir = tempDir;

  Future<void> start({
    int sampleRate = 48000,
    int bitRate = 96000,
    AudioEncoder encoder = AudioEncoder.aacLc,

  }) async {
    final granted = await (_checkPermissions ?? _record.hasPermission)();
    if (!granted) {
      throw Exception('Microphone or storage permission denied');
    }

    final dir = await (_getTempDir ?? getTemporaryDirectory)();
    final voiceDir = Directory('${dir.path}/voice');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = encoder == AudioEncoder.opus ? 'opus' : 'm4a';

    final path = '${voiceDir.path}/$timestamp.$extension';

    _filePath = path;
    _startTime = DateTime.now();


    await _record.start(
        RecordConfig(
          encoder: encoder,
          bitRate: bitRate,
          sampleRate: sampleRate,
          numChannels: 2,
        ),
        path: path
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

}
