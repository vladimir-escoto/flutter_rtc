// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/chat_input_bar/chat_input_bar.dart';

class ChatInputTestScreen extends StatefulWidget {
  const ChatInputTestScreen({super.key});

  @override
  State<ChatInputTestScreen>  createState() => _ChatInputTestScreenState();
}

class _ChatInputTestScreenState extends State<ChatInputTestScreen> {
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

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
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
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
            ),

            // Chat input bar
            ChatInputBar(
              onAttachmentTap: () => print('Attachment icon tapped'),
              onAttachmentSelected: (opt) =>
                  print('Selected attachment: $opt'),
              onShowCamera: () => print('Show camera called'),
              onSendMessage: (text) {
                print('Send text: $text');
                _addTextMessage(text);
              },
              onStartRecording: () => print('Recording started'),
              onStopRecording: () {
                print('Recording stopped & sending audio');
                _addAudioMessage();
              },
              onCancelRecording: () => print('Recording cancelled'),
              backgroundColor: Colors.white,
              iconColor: Colors.grey[700]!,
            ),
          ],
        ),
      ),
    );
  }
}

// Simple model for chat messages
class _ChatMessage {
  final String text;
  final bool isAudio;
  _ChatMessage({required this.text, this.isAudio = false});
}
