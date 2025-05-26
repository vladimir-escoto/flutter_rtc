// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:myapp/widgets/chat_input_bar/expandable_container.dart';

import 'widgets/attached_tooltip.dart';

class ChatInputTestScreen extends StatefulWidget {
  const ChatInputTestScreen({super.key});

  @override
  State<ChatInputTestScreen>  createState() => _ChatInputTestScreenState();
}

class _ChatInputTestScreenState extends State<ChatInputTestScreen> {
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isTooltipVisible = false;

  void _addTextMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isAudio: false));
    });
    _scrollToBottom();
  }

  void _addAudioMessage() {
    setState(() {
      _messages.add(_ChatMessage(text: '[Audio message]', isAudio: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: Text('Chat Test Home'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isAudio
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.isAudio
                            ? Colors.blueAccent.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (msg.isAudio) Icon(Icons.play_arrow),
                          SizedBox(width: msg.isAudio ? 6 : 0),
                          Text(msg.text),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),ExpandableContainer(
              width: MediaQuery.of(context).size.width,
              height: 50,
              collapsedRightWidth: 50,
              leftChild: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  autofocus: true,
                  style: TextStyle(color: Colors.black45),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              rightChildBuilder: (isExpanded, isAnimating) {
                return Container(
                  height: double.infinity,
                  color: Colors.white,
                  //padding: const EdgeInsets.only(right: 32),
                  child: Stack(
                    children: [
                      if (isExpanded && !isAnimating)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Slice to cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_back_ios_new, size: 24),
                              SizedBox(width: 80),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 60,
                          height: double.infinity,
                          color: Colors.red,
                          child: CompositedTransformTarget(
                            link: _layerLink,
                            child: Icon(Icons.mic, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              pinnedChild: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, color: Colors.red, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "00:00",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              onStart: () => debugPrint("Expand started"),
              onStop: () => debugPrint("Stopped by release"),
              onCancel: () => debugPrint("Canceled by threshold"),
              onFastCancel: () {
                debugPrint("Canceled by fast release");
                _showTooltip();
              },
            ),

            // Chat input bar
            // ChatInputBar(
            //   onAttachmentTap: () => print('Attachment icon tapped'),
            //   onAttachmentSelected: (opt) =>
            //       print('Selected attachment: $opt'),
            //   onShowCamera: () => print('Show camera called'),
            //   onSendMessage: (text) {
            //     print('Send text: $text');
            //     _addTextMessage(text);
            //   },
            //   onStartRecording: () => print('Recording started'),
            //   onStopRecording: () {
            //     print('Recording stopped & sending audio');
            //     _addAudioMessage();
            //   },
            //   onCancelRecording: () => print('Recording cancelled'),
            //   backgroundColor: Colors.white,
            //   iconColor: Colors.grey[700]!,
            // ),
          ],
        ),
      ),
    );
  }


  void _showTooltip() {
    if (_isTooltipVisible) return;

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          AttachedTooltip(
            link: _layerLink,
            message: 'Hold to record, release to send',
            offset: const Offset(-300, -50),
            width: 300,
            duration: const Duration(seconds: 2),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isTooltipVisible = true;

    Future.delayed(const Duration(seconds: 2), _hideTooltip);
  }

  void _hideTooltip() {
    if (!_isTooltipVisible) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isTooltipVisible = false;
  }
}

// Simple model for chat messages
class _ChatMessage {
  final String text;
  final bool isAudio;
  _ChatMessage({required this.text, this.isAudio = false});
}



