import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/widgets/chat_input_bar/chat_input_bar.dart';

void main() {
  Widget buildBar({VoidCallback? onStop, VoidCallback? onCancel}) {
    return MaterialApp(
      home: Material(
        child: ChatInputBar(
          onAttachmentTap: () {},
          onAttachmentSelected: (_) {},
          onShowCamera: () {},
          onSendMessage: (_) {},
          onStartRecording: () {},
          onStopRecording: onStop ?? () {},
          onCancelRecording: onCancel ?? () {},
        ),
      ),
    );
  }

  testWidgets('drag left cancels recording', (tester) async {
    var canceled = false;
    await tester.pumpWidget(buildBar(onCancel: () => canceled = true));

    final mic = find.bySemanticsLabel('Record audio');
    final gesture = await tester.startGesture(tester.getCenter(mic));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(canceled, isTrue);
  });

  testWidgets('drag up locks and send stops recording', (tester) async {
    var stopped = false;
    await tester.pumpWidget(buildBar(onStop: () => stopped = true));

    final mic = find.bySemanticsLabel('Record audio');
    final gesture = await tester.startGesture(tester.getCenter(mic));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byKey(const ValueKey('send_locked')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('send_locked')));
    await tester.pumpAndSettle();

    expect(stopped, isTrue);
  });
}
