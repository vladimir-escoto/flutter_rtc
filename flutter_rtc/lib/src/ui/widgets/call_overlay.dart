// lib/src/ui/widgets/call_overlay.dart

part of "../call_container_screen.dart";

class CallOverlay extends StatefulWidget {

  final Widget child;

  final CallViewBuilder? outgoingView;
  final CallViewBuilder? incomingView;
  final CallViewBuilder? activeCallView;
  final CallViewBuilder? endedView;
  final CallViewBuilder? declineView;
  final CallViewBuilder? minimizedView;
  final CallViewBuilder? holdView;
  final CallViewBuilder? errorView;

  const CallOverlay({
    super.key,
    required this.child,
    this.outgoingView,
    this.incomingView,
    this.activeCallView,
    this.endedView,
    this.declineView,
    this.minimizedView,
    this.holdView,
    this.errorView,
  });

  @override
  State<CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<CallOverlay> {
  /// This key ensures the same OverlayState is reused across rebuilds
  static final GlobalKey<OverlayState> _overlayKey =
  GlobalKey<OverlayState>(debugLabel: 'CallOverlay');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeOverlay());
  }

  void _initializeOverlay() {
    if (!mounted) return;

    CallOverlayManager.instance.setCustomBuilders(
        outgoingView: widget.outgoingView,
        incomingView: widget.incomingView,
        activeCallView: widget.activeCallView,
        endedView: widget.endedView,
        declineView: widget.declineView,
        minimizedView: widget.minimizedView,
        holdView: widget.holdView,
        errorView: widget.errorView);

    final overlayState = _overlayKey.currentState;

    if (overlayState != null) {
      debugPrint('[CallOverlay] Overlay.of(context)');
      CallOverlayManager.instance.initialize(overlayState);
    }
  }

  @override
  void dispose() {
    super.dispose();
    CallOverlayManager.instance.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: _overlayKey,
      initialEntries: [OverlayEntry(builder: (context) {
        debugPrint('[CallOverlay] OverlayEntry.builder');
        return widget.child;
      })],
    );
  }
}