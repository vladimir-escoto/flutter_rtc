// lib/src/ui/widgets/call_overlay.dart

part of "../call_container_screen.dart";

class CallOverlay extends StatelessWidget {
  final Widget child;

  final CallViewBuilder? outgoingView;
  final CallViewBuilder? incomingView;
  final CallViewBuilder? activeCallView;
  final CallViewBuilder? endedView;
  final CallViewBuilder? declineView;
  final CallViewBuilder? errorView;

  CallOverlay({
    super.key,
    required this.child,
    this.outgoingView,
    this.incomingView,
    this.activeCallView,
    this.endedView,
    this.declineView,
    this.errorView,
  }) {
    _setCustomBuilders();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[CallOverlay] build');
    return Overlay(
      initialEntries: [OverlayEntry(builder: (context) {
        debugPrint('[CallOverlay] Overlay.of(context)');
        CallOverlayManager.instance.initialize(Overlay.of(context));
        return child;
      })
      ],
    );
  }

  void _setCustomBuilders() {
    debugPrint('[CallOverlay] set CustomBuilders');
    CallOverlayManager.instance.setCustomBuilders(outgoingView: outgoingView,
        incomingView: incomingView,
        activeCallView: activeCallView,
        endedView: endedView,
        declineView: declineView,
        errorView: errorView);
  }
}