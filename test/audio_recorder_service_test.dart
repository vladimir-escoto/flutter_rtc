import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:record/record.dart' as rec;
import 'package:flutter_rtc/services/audio_recorder_service.dart';

class MockRecord extends Mock implements rec.Record {}

void main() {
  group('AudioRecorderService', () {
    late MockRecord record;
    late Directory tempDir;

    setUp(() async {
      record = MockRecord();
      tempDir = await Directory.systemTemp.createTemp('audio_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('start and stop returns result with file', () async {
      String? capturedPath;
      when(record.start(
        path: anyNamed('path'),
        encoder: anyNamed('encoder'),
        bitRate: anyNamed('bitRate'),
        samplingRate: anyNamed('samplingRate'),
      )).thenAnswer((invocation) async {
        capturedPath = invocation.namedArguments[const Symbol('path')] as String;
      });
      when(record.stop()).thenAnswer((_) async => capturedPath);

      final service = AudioRecorderService(
        record: record,
        checkPermissions: () async => true,
        tempDir: () async => tempDir,
      );

      await service.start();
      final result = await service.stop();

      expect(result.file.path, capturedPath);
      expect(result.durationSeconds >= 0, isTrue);
      verify(record.start(
        path: anyNamed('path'),
        encoder: anyNamed('encoder'),
        bitRate: anyNamed('bitRate'),
        samplingRate: anyNamed('samplingRate'),
      )).called(1);
      verify(record.stop()).called(1);
    });

    test('throws when permissions denied', () async {
      final service = AudioRecorderService(
        record: record,
        checkPermissions: () async => false,
        tempDir: () async => tempDir,
      );

      expect(service.start(), throwsException);
      verifyNever(record.start(
        path: anyNamed('path'),
        encoder: anyNamed('encoder'),
        bitRate: anyNamed('bitRate'),
        samplingRate: anyNamed('samplingRate'),
      ));
    });

    test('cancel deletes file', () async {
      String? capturedPath;
      when(record.start(
        path: anyNamed('path'),
        encoder: anyNamed('encoder'),
        bitRate: anyNamed('bitRate'),
        samplingRate: anyNamed('samplingRate'),
      )).thenAnswer((invocation) async {
        capturedPath = invocation.namedArguments[const Symbol('path')] as String;
        await File(capturedPath!).create(recursive: true);
      });
      when(record.stop()).thenAnswer((_) async => capturedPath);

      final service = AudioRecorderService(
        record: record,
        checkPermissions: () async => true,
        tempDir: () async => tempDir,
      );

      await service.start();
      await service.cancel();

      expect(File(capturedPath!).existsSync(), isFalse);
    });
  });
}
