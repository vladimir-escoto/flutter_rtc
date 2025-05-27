// File: lib/widgets/chat_input_bar/chat_input_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AttachmentOption { photos, camera, location, contacts, documents }

enum _InputMode { idle, keyboard, attachments, recording, recordingLocked }

class ChatInputBar extends StatefulWidget {
  final VoidCallback onAttachmentTap;
  final void Function(AttachmentOption option) onAttachmentSelected;
  final VoidCallback onShowCamera;
  final void Function(String text) onSendMessage;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;

  // Theming
  final Color backgroundColor;
  final Color iconColor;
  final Duration animationDuration;

  // I18n
  final String hintText;
  final String holdToRecordTooltip;

  const ChatInputBar({
    super.key,
    required this.onAttachmentTap,
    required this.onAttachmentSelected,
    required this.onShowCamera,
    required this.onSendMessage,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.grey,
    this.animationDuration = const Duration(milliseconds: 300),
    this.hintText = 'Type a message',
    this.holdToRecordTooltip = 'Hold to record, release to send',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _InputMode _mode = _InputMode.idle;

  Timer? _recordTimer;
  int _recordSeconds = 0;
  DateTime? _recordStartTime;

  OverlayEntry? _tooltipOverlay;

  static const int _minRecordingSeconds = 1;
  static const double _cancelThreshold = -75.0;
  static const double _lockThreshold = -60.0;

  double dragOffset = 0;
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _dragAnimation = Tween<double>(begin: 0, end: 0).animate(_dragAnimationController)
      ..addListener(() {
        setState(() {
          dragOffset = _dragAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    _recordTimer?.cancel();
    _tooltipOverlay?.remove();
    _dragAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _collapseAll();
    }
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() => _mode = _InputMode.keyboard);
    }
  }

  void _toggleAttachments() {
    if (_mode == _InputMode.attachments) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _mode = _InputMode.attachments);
      widget.onAttachmentTap();
    }
  }

  void _onMicTapDown(TapDownDetails details) {
    if (_mode != _InputMode.recording && _mode != _InputMode.recordingLocked) {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_mode == _InputMode.recording || _mode == _InputMode.recordingLocked) return;
    HapticFeedback.lightImpact();
    setState(() {
      _mode = _InputMode.recording;
      dragOffset = 0;
      _recordSeconds = 0;
      _recordStartTime = DateTime.now();
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
    widget.onStartRecording();
  }

  void _lockRecording() {
    if (_mode != _InputMode.recording) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _mode = _InputMode.recordingLocked;
    });
  }

  void _onMicTapUp(TapUpDetails details) {
    if (_mode == _InputMode.recordingLocked) {
      return;
    }
    if (_mode == _InputMode.recording) {
      final duration = DateTime.now().difference(_recordStartTime ?? DateTime.now());
      if (duration.inSeconds >= _minRecordingSeconds) {
        _stopRecording();
      } else {
        _cancelRecordingWithReturn();
      }
    }
  }

  void _onMicLongPressEnd(LongPressEndDetails details) {
    if (_mode == _InputMode.recordingLocked) {
      return;
    }
    if (_mode == _InputMode.recording) {
      final duration = DateTime.now().difference(_recordStartTime ?? DateTime.now());
      if (duration.inSeconds >= _minRecordingSeconds) {
        _stopRecording();
      } else {
        _cancelRecordingWithReturn();
      }
    }
  }

  void _cancelRecordingWithReturn() {
    _animateMicReturn(() {
      _cancelRecording();
    });
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    HapticFeedback.lightImpact();
    HapticFeedback.lightImpact();
    widget.onCancelRecording();
    _resetRecordingState();
  }

  void _stopRecording({bool heavy = false}) {
    _recordTimer?.cancel();
    if (heavy) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    widget.onStopRecording();
    _resetRecordingState();
  }

  void _sendLockedRecording() {
    if (_mode != _InputMode.recordingLocked) return;
    _stopRecording(heavy: true);
  }

  void _cancelLockedRecording() {
    if (_mode != _InputMode.recordingLocked) return;
    _cancelRecording();
  }

  void _resetRecordingState() {
    setState(() {
      dragOffset = 0;
      _mode = _InputMode.idle;
      _recordSeconds = 0;
      _recordStartTime = null;
    });
  }

  void _collapseAll() {
    _focusNode.unfocus();
    _recordTimer?.cancel();
    _tooltipOverlay?.remove();
    setState(() {
      _mode = _InputMode.idle;
      _controller.clear();
      _recordSeconds = 0;
      _recordStartTime = null;
    });
  }

  void _handleTapOutside() {
    _collapseAll();
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (_mode != _InputMode.recording) return;
    final dx = details.offsetFromOrigin.dx;
    final dy = details.offsetFromOrigin.dy;
    if (dy < _lockThreshold) {
      _lockRecording();
      return;
    }
    if (dx < _cancelThreshold) {
      _cancelRecordingWithReturn();
      return;
    }
    setState(() {
      dragOffset = -dx.clamp(_cancelThreshold, 0.0);
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_mode != _InputMode.recording) return;
    setState(() {
      dragOffset += details.delta.dx;
      if (dragOffset < _cancelThreshold) {
        _cancelRecordingWithReturn();
      } else if (dragOffset > 0) {
        dragOffset = 0;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_mode != _InputMode.recording) return;
    _animateMicReturn();
  }

  void _animateMicReturn([VoidCallback? onCompleted]) {
    _dragAnimation = Tween<double>(
      begin: dragOffset,
      end: 0,
    ).animate(CurvedAnimation(parent: _dragAnimationController, curve: Curves.easeOut));
    _dragAnimationController
      ..reset()
      ..forward().whenComplete(() {
        if (onCompleted != null) onCompleted();
      });
  }

  void _showHoldToRecordTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    _tooltipOverlay = OverlayEntry(
      builder:
          (_) => Positioned(
            left: offset.dx + 60,
            bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.holdToRecordTooltip,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
    );
    overlay.insert(_tooltipOverlay!);
    Future.delayed(const Duration(seconds: 2), () {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_mode != _InputMode.idle)
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleTapOutside,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: widget.animationDuration,
            color: widget.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: _buildInputRow(),
          ),
        ),
        if (_mode == _InputMode.recording)
          Positioned.fill(
            child: AnimatedContainer(
              duration: widget.animationDuration,
              color: widget.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: AnimatedSwitcher(
                duration: widget.animationDuration,
                child: RecordingPanel(
                  key: ValueKey('recording_panel'),
                  duration: Duration(seconds: _recordSeconds),
                ),
              ),
            ),
          ),
        if (_mode == _InputMode.recordingLocked)
          Positioned.fill(
            child: AnimatedContainer(
              duration: widget.animationDuration,
              color: widget.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  RecordingPanel(
                    key: const ValueKey('recording_panel_locked'),
                    duration: Duration(seconds: _recordSeconds),
                  ),
                  const Spacer(),
                  Semantics(
                    label: 'Delete recording',
                    child: IconButton(
                      key: const ValueKey('delete_locked'),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _cancelLockedRecording,
                    ),
                  ),
                  Semantics(
                    label: 'Send audio',
                    child: IconButton(
                      key: const ValueKey('send_locked'),
                      icon: const Icon(Icons.send, color: Colors.green),
                      onPressed: _sendLockedRecording,
                    ),
                  ),
                ],
              ),
            ),
          ),

        Positioned(
          right: dragOffset,
          bottom: 0,
          top: 0,
          child: Semantics(
            label: "Record audio",
            child: GestureDetector(
              onTap: _showHoldToRecordTooltip,
              onTapDown: _onMicTapDown,
              onTapUp: _onMicTapUp,
              onLongPressStart: (_) => _startRecording(),
              onLongPressMoveUpdate: _onLongPressMove,
              onLongPressCancel: () {},
              onLongPressEnd: _onMicLongPressEnd,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Row(
                children: [
                  if (_mode == _InputMode.recording)
                    WaveAnimation(
                      child: Row(
                        children: [
                          Text(
                            "Slide left to cancel",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.grey.shade700,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _mode == _InputMode.recording || _mode == _InputMode.recordingLocked
                          ? Colors.red.withValues(alpha: 0.12)
                          : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _mode == _InputMode.recordingLocked ? Icons.lock : Icons.mic,
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow() {
    final hasText = _controller.text.trim().isNotEmpty;

    return Row(
      children: [
        Semantics(
          label: "Attach file",
          child: IconButton(
            icon: Icon(Icons.attach_file, color: widget.iconColor),
            onPressed: _toggleAttachments,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.emoji_emotions, color: widget.iconColor),
                onPressed: () {
                  _focusNode.requestFocus();
                },
                tooltip: "Open emoji picker",
              ),
            ),
            onTap: () {
              if (_mode == _InputMode.attachments) {
                setState(() => _mode = _InputMode.keyboard);
                _focusNode.requestFocus();
              }
            },
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                widget.onSendMessage(text.trim());
                _controller.clear();
              }
            },
          ),
        ),
        if (hasText)
          Semantics(
            label: "Send message",
            child: IconButton(
              icon: Icon(Icons.send, color: widget.iconColor),
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  widget.onSendMessage(text);
                  _controller.clear();
                }
              },
            ),
          )
        else ...[
          Semantics(
            label: "Open camera",
            child: IconButton(
              icon: Icon(Icons.camera_alt, color: widget.iconColor),
              onPressed: widget.onShowCamera,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ],
    );
  }
}

class WaveAnimation extends StatefulWidget {
  final Widget child;

  const WaveAnimation({super.key, required this.child});

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [Colors.grey.shade700, Colors.white, Colors.grey.shade700],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              tileMode: TileMode.repeated,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class RecordingPanel extends StatelessWidget {
  final Duration duration;

  const RecordingPanel({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Icon(Icons.mic, color: Colors.red),
        const SizedBox(width: 12),
        Text(
          '$minutes:$seconds',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
