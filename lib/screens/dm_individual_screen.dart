import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../models/match_convo.dart';
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
  bool _isReady = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    myUserId = _conversationService.currentUserId;
    _scrollController = ScrollController();
    _loadMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      setState(() => _isReady = true); // ✅ reveal after scroll
    });
  }

  Future<void> _loadMessages() async {
    try {
      final fetchedMaps = await _conversationService.getMessages(
        myUserId,
        widget.chat.otherUserId,
      );
      setState(() {
        _messages = fetchedMaps.map((row) {
          final senderId = row['sender_id'] as String;
          return _Message(
            text: row['content'] ?? '',
            fromMe: senderId == myUserId,
          );
        }).toList();
        // Map strings over to your custom visual _Message objects
        _isLoading = false; // Loading complete!
      });
      _scrollToBottom();
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
      _conversationService.recordMessage(
        text,
        myUserId,
        widget.chat.otherUserId,
      );
    });
    _scrollToBottom();
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _hints() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Hints'),
        content: Text(
          '''Here's some helpful prompts to help you chat to ${widget.chat.name}:
          \n- "What are your favorite hobbies?"
          \n- "Have you traveled anywhere interesting recently?"''',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BACK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              ProfilePicture(
                name: widget.chat.name,
                radius: 20,
                fontsize: 16,
                random: false,
                img:
                    widget.chat.imageUrl != null &&
                        widget.chat.imageUrl!.isNotEmpty
                    ? widget.chat.imageUrl
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.chat.name),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: _hints,
              tooltip: 'Prompts to help you chat with ${widget.chat.name}',
              iconSize: 36,
            ),
          ],
          backgroundColor: const Color(0XFF84DCC6),
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimatedOpacity(
                opacity: _isReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Interests Card (always at top) ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0XFFEEC0C6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Interests:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...widget.chat.interests.map(
                                          (interest) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '★ ',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    interest,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Messages ──
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: _messages.map((message) {
                                      return Align(
                                        alignment: message.fromMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: message.fromMe
                                                ? const Color(0XFF8789C0)
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                16,
                                              ),
                                              topRight: const Radius.circular(
                                                16,
                                              ),
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
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                textCapitalization:
                                    TextCapitalization.sentences,
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
              ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool fromMe;

  _Message({required this.text, required this.fromMe});
}
