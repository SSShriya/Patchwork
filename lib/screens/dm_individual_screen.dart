import 'package:drp/widgets/dm_meeting_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';
import '../widgets/user_profile_card.dart';

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
      setState(() => _isReady = true);
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
          final content = row['content'] ?? '';

          // Checks if it is a local rich client object OR the string fallback recorded in database tables
          final isInvite =
              content.startsWith('INVITATION_DATA:') ||
              content == 'Invitation sent.';

          return _Message(
            text: content,
            fromMe: senderId == myUserId,
            isInvitation: isInvite,
            invitationStatus: isInvite ? 'pending' : null,
          );
        }).toList();
        _isLoading = false;
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

  void _suggestMeeting() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const DMMeetingPopup(),
    );

    if (result != null) {
      final String rawInvitePayload =
          "INVITATION_DATA:{"
          "\"date\":\"${result['date']}\","
          "\"time\":\"${result['time']}\","
          "\"location\":\"${result['location'] ?? ''}\""
          "}";

      setState(() {
        // Render rich graphical box inside local view interface immediately
        _messages.add(
          _Message(
            text: rawInvitePayload,
            fromMe: true,
            isInvitation: true,
            invitationStatus: 'pending',
          ),
        );

        // Write standard text transaction identifier label value down to backend tables
        _conversationService.recordMessage(
          'Invitation sent.',
          myUserId,
          widget.chat.otherUserId,
        );
      });
      _scrollToBottom();
    }
  }

  void _handleInvitationResponse(int messageIndex, bool accepted) {
    setState(() {
      _messages[messageIndex].invitationStatus = accepted
          ? 'accepted'
          : 'rejected';
    });

    final String resultText = accepted
        ? "Accepted the invitation"
        : "Declined the invitation";

    _conversationService.recordMessage(
      "=== $resultText ===",
      myUserId,
      widget.chat.otherUserId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _hints() {
    final interests = widget.chat.interests;
    final event = widget.chat.event;

    final prompts = [
      if (interests.isNotEmpty)
        'How long have you been interested in ${interests[0]}?',
      if (interests.length > 1) 'What got you into ${interests[1]}?',
      if (interests.length > 2)
        'Do you have any tips for someone getting into ${interests[2]}?',
      if (event.isNotEmpty) 'What made you interested in $event?',
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prompts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap a prompt to send it to ${widget.chat.name}:'),
            const SizedBox(height: 12),
            ...prompts.map(
              (prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    _controller.text = prompt;
                    _send();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0XFF84DCC6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0XFF84DCC6),
                        width: 1,
                      ),
                    ),
                    child: Text(prompt, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ),
          ],
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
          title: GestureDetector(
            onTap: () {
              final card = widget.chat.matchCard;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      backgroundColor: const Color(0XFF84DCC6),
                      foregroundColor: Colors.white,
                      title: Text(card.title),
                    ),
                    body: UserProfileCard(card: card),
                  ),
                ),
              );
            },
            child: Row(
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
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _suggestMeeting,
              tooltip:
                  'Suggest a time/place to meet ${widget.chat.name} before ${widget.chat.event}!',
              iconSize: 36,
            ),
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
                                if (widget.chat.event.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'You are both going to: ${widget.chat.event.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
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
                                        Text(
                                          '${widget.chat.name}\'s Interests:',
                                          style: const TextStyle(
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: List.generate(_messages.length, (
                                      index,
                                    ) {
                                      final msg = _messages[index];
                                      if (msg.isInvitation) {
                                        return _buildInvitationBox(msg, index);
                                      }
                                      return Align(
                                        alignment: msg.fromMe
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
                                            color: msg.fromMe
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
                                                msg.fromMe ? 16 : 0,
                                              ),
                                              bottomRight: Radius.circular(
                                                msg.fromMe ? 0 : 16,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            msg.text,
                                            style: TextStyle(
                                              color: msg.fromMe
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
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

  Widget _buildInvitationBox(_Message msg, int index) {
    final String cleanData = msg.text.replaceFirst('INVITATION_DATA:', '');

    String extractedDate = "Details saved";
    String extractedTime = "Details saved";
    String extractedLoc = "Check event panel updates";

    // Prevent parsing errors if structural payload was omitted when saving back to server database
    if (msg.text == 'Invitation sent.') {
      extractedDate = "Details in notification";
      extractedTime = "Details in notification";
      extractedLoc = "Check your system alerts";
    } else {
      try {
        final RegExp dateRegex = RegExp(r'"date":"([^"]+)"');
        final RegExp timeRegex = RegExp(r'"time":"([^"]+)"');
        final RegExp locRegex = RegExp(r'"location":"([^"]*)"');

        if (dateRegex.hasMatch(cleanData)) {
          extractedDate = dateRegex.firstMatch(cleanData)!.group(1)!;
        }
        if (timeRegex.hasMatch(cleanData)) {
          extractedTime = timeRegex.firstMatch(cleanData)!.group(1)!;
        }
        if (locRegex.hasMatch(cleanData)) {
          final locVal = locRegex.firstMatch(cleanData)!.group(1)!;
          if (locVal.isNotEmpty) extractedLoc = locVal;
        }
      } catch (_) {}
    }

    final bool isPending = msg.invitationStatus == 'pending';

    return Align(
      alignment: msg.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0XFF8789C0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0XFF8789C0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.fromMe ? 'Meeting Sent' : 'Meeting Invitation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📅 Date: $extractedDate",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "⏰ Time: $extractedTime",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "📍 Location: $extractedLoc",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),

                  const Divider(height: 16),

                  if (isPending) ...[
                    if (!msg.fromMe) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () =>
                                  _handleInvitationResponse(index, false),
                              child: const Text(
                                'Reject',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0XFF84DCC6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () =>
                                  _handleInvitationResponse(index, true),
                              child: const Text(
                                'Accept',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Center(
                        child: Text(
                          'Waiting for reply...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: msg.invitationStatus == 'accepted'
                              ? const Color(0XFF84DCC6).withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msg.invitationStatus == 'accepted'
                              ? 'Accepted ✓'
                              : 'Declined ✕',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: msg.invitationStatus == 'accepted'
                                ? const Color(0XFF409A83)
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool fromMe;
  final bool isInvitation;
  String? invitationStatus;

  _Message({
    required this.text,
    required this.fromMe,
    this.isInvitation = false,
    this.invitationStatus,
  });
}
