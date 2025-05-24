import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:record/record.dart';
import 'package:flutter_rtc/services/audio_recorder_service.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}

void main() {
  group('AudioRecorderService', () {
    late MockAudioRecorder recorder;
    late Directory tempDir;

    setUp(() async {
      recorder = MockAudioRecorder();
      tempDir = await Directory.systemTemp.createTemp('audio_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('start and stop returns result with file', () async {
      String? capturedPath;
      when(recorder.start(any, path: anyNamed('path'))).thenAnswer((invocation) async {
        capturedPath = invocation.namedArguments[const Symbol('path')] as String;
      });
      when(recorder.stop()).thenAnswer((_) async => capturedPath);

      final service = AudioRecorderService(
        recorder: recorder,
        checkPermissions: () async => true,
        tempDir: () async => tempDir,
      );

      await service.start();
      final result = await service.stop();

      expect(result.file.path, capturedPath);
      expect(result.durationSeconds >= 0, isTrue);
      verify(recorder.start(any, path: anyNamed('path'))).called(1);
      verify(recorder.stop()).called(1);
    });

    test('throws when permissions denied', () async {
      final service = AudioRecorderService(
        recorder: recorder,
        checkPermissions: () async => false,
        tempDir: () async => tempDir,
      );

      expect(service.start(), throwsException);
      verifyNever(recorder.start(any, path: anyNamed('path')));
    });

    test('cancel deletes file', () async {
      String? capturedPath;
      when(recorder.start(any, path: anyNamed('path'))).thenAnswer((invocation) async {
        capturedPath = invocation.namedArguments[const Symbol('path')] as String;
        await File(capturedPath!).create(recursive: true);
      });
      when(recorder.cancel()).thenAnswer((_) async {});

      final service = AudioRecorderService(
        recorder: recorder,
        checkPermissions: () async => true,
        tempDir: () async => tempDir,
      );

      await service.start();
      await service.cancel();

      expect(File(capturedPath!).existsSync(), isFalse);
    });
  });
}
