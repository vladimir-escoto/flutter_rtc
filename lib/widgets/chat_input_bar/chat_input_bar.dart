// File: lib/widgets/chat_input_bar/chat_input_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AttachmentOption { photos, camera, location, contacts, documents }

enum _InputMode { idle, keyboard, attachments, recording }

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

class _ChatInputBarState extends State<ChatInputBar> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _InputMode _mode = _InputMode.idle;

  Timer? _recordTimer;
  int _recordSeconds = 0;
  DateTime? _recordStartTime;

  OverlayEntry? _tooltipOverlay;

  static const int _minRecordingSeconds = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    _recordTimer?.cancel();
    _tooltipOverlay?.remove();
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

  // Start recording on tap down
  void _onMicTapDown(TapDownDetails details) {
    debugPrint("_onMicTapDown");
    if (_mode != _InputMode.recording) {
      _startRecording();
    }
  }

  void _startRecording() {
    if (_mode == _InputMode.recording) return;
    debugPrint("_startRecording");
    HapticFeedback.lightImpact();
    setState(() {
      _mode = _InputMode.recording;
      _recordSeconds = 0;
      _recordStartTime = DateTime.now();
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
    widget.onStartRecording();
  }

  // On release, decide whether to send or cancel
  void _onMicTapUp(TapUpDetails details) {
    debugPrint("_onMicTapUp");
    if (_mode == _InputMode.recording) {
      final duration = DateTime.now().difference(_recordStartTime ?? DateTime.now());
      if (duration.inSeconds >= _minRecordingSeconds) {
        _stopRecording();
      } else {
        _cancelRecording();
      }
    }
  }

  // Backup for long press gesture as well
  void _onMicLongPressEnd(LongPressEndDetails details) {
    if (_mode == _InputMode.recording) {
      final duration = DateTime.now().difference(_recordStartTime ?? DateTime.now());
      if (duration.inSeconds >= _minRecordingSeconds) {
        _stopRecording();
      } else {
        _cancelRecording();
      }
    }
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    widget.onCancelRecording();
    _resetRecordingState();
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    HapticFeedback.lightImpact();
    widget.onStopRecording();
    _resetRecordingState();
  }

  void _resetRecordingState() {
    setState(() {
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

  // For cancel by slide up
  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (details.offsetFromOrigin.dy < -50) {
      _cancelRecording();
    }
  }

  void _showHoldToRecordTooltip() {
    debugPrint("_showHoldToRecordTooltip");
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
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: widget.animationDuration,
            color: widget.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: AnimatedSwitcher(
              duration: widget.animationDuration,
              child:
                  (_mode == _InputMode.recording)
                      ? RecordingPanel(
                        key: ValueKey('recording_panel'),
                        duration: Duration(seconds: _recordSeconds),
                        animationDuration: widget.animationDuration,
                        onStop: _stopRecording,
                        onCancel: _cancelRecording,
                      )
                      : const SizedBox.shrink(),
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
                  // TODO: implement emoji picker
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
          Semantics(
            label: "Record audio",
            child: GestureDetector(
              onTap: _showHoldToRecordTooltip,
              onTapDown: _onMicTapDown,
              onTapUp: _onMicTapUp,
              onLongPressStart: (_) => _startRecording(),
              onLongPressMoveUpdate: _onLongPressMove,
              onLongPressEnd: _onMicLongPressEnd,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color:
                      _mode == _InputMode.recording
                          ? Colors.red.withOpacity(0.12)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.mic, color: widget.iconColor),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RecordingPanel extends StatelessWidget {
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const RecordingPanel({
    super.key,
    required this.duration,
    required this.animationDuration,
    required this.onStop,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      children: [
        const Icon(Icons.mic, color: Colors.red),
        const SizedBox(width: 12),
        Text(
          '$minutes:$seconds',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            "Slide up to cancel",
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: onCancel),
      ],
    );
  }
}
