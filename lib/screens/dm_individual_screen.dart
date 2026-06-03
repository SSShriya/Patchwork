import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import 'package:bulleted_list/bulleted_list.dart';
import '../services/conversation_service.dart';

class DMScreen extends StatefulWidget {
  final ChatConversation chat;

  const DMScreen({super.key, required this.chat});

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final TextEditingController _controller = TextEditingController();
  final ConversationService _conversationService = ConversationService();
  late final String myUserId;
  List<String> messages = [];
  List<_Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    myUserId = _conversationService.currentUserId;
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final fetchedMaps = await _conversationService.getMessages(myUserId, widget.chat.otherUserId);
      setState(() {
        _messages = fetchedMaps.map((row) {
          final senderId = row['sender_id'] as String;
          return _Message(
            text: row['content'] ?? '',
            fromMe: senderId == myUserId,
          );
        }).toList();
        // Map strings over to your custom visual _Message objects
        _messages = messages.map((m) => _Message(text: m, fromMe: true)).toList();
        _isLoading = false; // Loading complete!
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching messages: $e");
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, fromMe: true));
      _conversationService.recordMessage(text, myUserId, widget.chat.otherUserId);
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0XFF8789C0),
              child: Text(
                widget.chat.name[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.chat.name),
          ],
        ),
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          :
      Column(
        children: [
          SizedBox(height: 16),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Text(
                          'Interests:',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        BulletedList(
                          listItems: widget.chat.interests,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.fromMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: message.fromMe
                                ? const Color(0XFF8789C0)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(
                                message.fromMe ? 16 : 0,
                              ),
                              bottomRight: Radius.circular(
                                message.fromMe ? 0 : 16,
                              ),
                            ),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.fromMe
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.chat.name}...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0XFF84DCC6),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool fromMe;

  _Message({required this.text, required this.fromMe});
}
