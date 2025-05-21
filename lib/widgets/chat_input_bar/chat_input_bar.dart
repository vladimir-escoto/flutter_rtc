import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'attachment_panel.dart';
import 'recording_panel.dart';

/// Attachment options for the panel.
enum AttachmentOption { photos, camera, location, contacts, documents }

/// ChatInputBar: text input + attachments + emoji + camera + audio recording.
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
  });

  @override
  _ChatInputBarState createState() => _ChatInputBarState();
}

enum _InputMode { idle, keyboard, attachments, recording }

class _ChatInputBarState extends State<ChatInputBar>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _InputMode _mode = _InputMode.idle;

  Timer? _recordTimer;
  int _recordSeconds = 0;

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cancel recording if app goes background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_mode == _InputMode.recording) _cancelRecording();
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

  void _startRecording() {
    setState(() => _mode = _InputMode.recording);
    _recordSeconds = 0;
    _recordTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });
    widget.onStartRecording();
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    widget.onStopRecording();
    _reset();
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    widget.onCancelRecording();
    _reset();
  }

  void _reset() {
    setState(() {
      _mode = _InputMode.idle;
      _controller.clear();
    });
  }

  void _handleTapOutside() {
    if (_mode != _InputMode.idle) {
      _focusNode.unfocus();
      setState(() => _mode = _InputMode.idle);
    }
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    // if dragged up beyond threshold, cancel
    if (details.offsetFromOrigin.dy < -50) {
      _cancelRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Detect taps outside to collapse
        if (_mode != _InputMode.idle)
          Positioned.fill(
            child: GestureDetector(
              onTap: _handleTapOutside,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        // Input area + panels
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: widget.animationDuration,
            color: widget.backgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputRow(),
                // Attachment panel
                AttachmentPanel(
                  visible: _mode == _InputMode.attachments,
                  animationDuration: widget.animationDuration,
                  onSelected: widget.onAttachmentSelected,
                ),
                // Recording panel
                if (_mode == _InputMode.recording)
                  RecordingPanel(
                    duration: Duration(seconds: _recordSeconds),
                    animationDuration: widget.animationDuration,
                    onStop: _stopRecording,
                    onCancel: _cancelRecording,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        // Attachment icon
        IconButton(
          icon: Icon(Icons.attach_file, color: widget.iconColor),
          onPressed: _toggleAttachments,
        ),
        // Text field
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Type a message',
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.emoji_emotions, color: widget.iconColor),
                onPressed: () {
                  // TODO: open emoji picker
                },
              ),
            ),
          ),
        ),
        // Send / camera + mic
        if (_controller.text.trim().isNotEmpty)
          IconButton(
            icon: Icon(Icons.send, color: widget.iconColor),
            onPressed: () =>
                widget.onSendMessage(_controller.text.trim()),
          )
        else ...[
          IconButton(
            icon: Icon(Icons.camera_alt, color: widget.iconColor),
            onPressed: widget.onShowCamera,
          ),
          GestureDetector(
            onTap: () {
              final tooltip = Tooltip(
                message: 'Hold to record, release to send',
                child: SizedBox.shrink(),
              );
              final entry = OverlayEntry(builder: (_) => tooltip);
              Overlay.of(context)?.insert(entry);
              Future.delayed(Duration(seconds: 2), entry.remove);
            },
            onLongPressStart: (_) => _startRecording(),
            onLongPressMoveUpdate: _onLongPressMove,
            onLongPressEnd: (_) => _stopRecording(),
            child: Icon(Icons.mic, color: widget.iconColor),
          ),
        ],
      ],
    );
  }
}
