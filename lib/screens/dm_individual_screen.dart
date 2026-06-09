import 'dart:async';
import 'package:drp/services/utils.dart';
import 'package:drp/widgets/dm_meeting_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';
import '../widgets/user_profile_card.dart';

class DMScreen extends StatefulWidget {
  final ChatConversation chat;
  final bool suggestMeeting; 

  const DMScreen({super.key, required this.chat, this.suggestMeeting = false});

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final TextEditingController _controller = TextEditingController();
  final ConversationService _conversationService = ConversationService();
  late final String myUserId; // initialized in loadMessages()
  List<_Message> _messages = [];
  bool _isLoading = true;
  bool _isReady = false;
  late final ScrollController _scrollController;

  // 2. Reference link tracker for the periodic interval hook
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initChatAndStartPolling();
    if (widget.suggestMeeting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _suggestMeeting();
      });
    }
  }

  // 3. Setup sequential initialization: get userId background values, pull historical UI data, then spin loop
  Future<void> _initChatAndStartPolling() async {
    myUserId = await loadUserId();
    // Immediate initial sync pull
    await _loadMessages(forceScroll: true);

    // Periodically execution block firing precisely down to 1-second ticks
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadMessages(forceScroll: false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      if (!_isReady) setState(() => _isReady = true);
    });
  }

  // 4. Enhanced database sync mechanism tracking length updates to conditionally slide screen focus
  Future<void> _loadMessages({bool forceScroll = false}) async {
    try {
      final fetchedMaps = await _conversationService.getMessages(
        myUserId,
        widget.chat.otherUserId,
      );

      final List<_Message> freshMessages = fetchedMaps.map((row) {
        final senderId = row['sender_id'] as String;
        final content = row['content'] ?? '';
        final isInvite = content.startsWith('INVITATION_DATA:');

        return _Message(
          id: row['message_id']?.toString() ?? '',
          text: content,
          fromMe: senderId == myUserId,
          createdAt: DateTime.parse(row['created_at']),
          isInvitation: isInvite,
          invitationStatus: isInvite
              ? (row['invitation_status'] as bool?)
              : null,
        );
      }).toList();

      // Check if data metrics changed before updating visual element arrays
      final bool hasNewMessages =
          freshMessages.length != _messages.length ||
          freshMessages.any((fresh) {
            final existing = _messages.firstWhere(
              (m) => m.id == fresh.id,
              orElse: () => fresh,
            );
            return existing.invitationStatus != fresh.invitationStatus;
          });

      if (mounted) {
        setState(() {
          _messages = freshMessages;
          _isLoading = false;
        });

        // Only move focus down if forced or when a novel string entry appears
        if (forceScroll || hasNewMessages) {
          _scrollToBottom();
        } else if (!_isReady) {
          setState(() => _isReady = true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReady = true;
        });
      }
      debugPrint("Error fetching messages: $e");
    }
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    final id = await _conversationService.recordMessage(
      text,
      myUserId,
      widget.chat.otherUserId,
    );

    setState(() {
      _messages.add(_Message(id: id, text: text, fromMe: true, createdAt: DateTime.now()));
    });
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

      final id = await _conversationService.recordMessage(
        rawInvitePayload,
        myUserId,
        widget.chat.otherUserId,
      );

      setState(() {
        _messages.add(
          _Message(
            id: id,
            text: rawInvitePayload,
            fromMe: true,
            isInvitation: true,
            invitationStatus: null,
            createdAt: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    }
  }

  void _handleInvitationResponse(int messageIndex, bool accepted) async {
    final id = _messages[messageIndex].id;

    debugPrint(
      'Handling response: index=$messageIndex id=$id status=$accepted',
    );

    setState(() {
      _messages[messageIndex].invitationStatus = accepted;
    });

    try {
      await _conversationService.updateInvitationStatus(id, accepted);
      debugPrint('Response handled successfully');
    } catch (e) {
      debugPrint('_handleInvitationResponse error: $e');
    }
  }

  // 5. Explicit disposal cleanups ensuring garbage collecting clears the active continuous ticks
  @override
  void dispose() {
    _pollingTimer?.cancel(); // Kill background timer interval
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
                    body: UserProfileCard(card: card, accepted: true,),
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
              icon: const Icon(Icons.event),
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
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          const SizedBox(height: 16),

                          // Event banner
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

                          // Interests card
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0XFFEEC0C6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding: const EdgeInsets.only(bottom: 4),
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

                          // Messages
                          ...buildGroupedMessages(),
                        ],
                      ),
                    ),

                    // Input bar — unchanged
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

    String extractedDate = "Not specified";
    String extractedTime = "Not specified";
    String extractedLoc = "Not specified";

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

    final bool isPending = msg.invitationStatus == null;

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
                          color: msg.invitationStatus == true
                              ? const Color(0XFF84DCC6).withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msg.invitationStatus == true
                              ? 'Accepted ✓'
                              : 'Declined ✕',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: msg.invitationStatus == true
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

  List<Widget> buildGroupedMessages() {
    final widgets = <Widget>[];

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final prev = i > 0 ? _messages[i - 1] : null;

      final showDateHeader = prev == null ||
          formatGroupDate(prev.createdAt) != formatGroupDate(msg.createdAt);

      if (showDateHeader) {
        widgets.add(
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatGroupDate(msg.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
        );
      }

      if (msg.isInvitation) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildInvitationBox(msg, i),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: msg.fromMe
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: msg.fromMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.fromMe
                        ? const Color(0XFF8789C0)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(msg.text),
                ),

                const SizedBox(height: 2),

                // timestamp
                Text(
                  formatTime(msg.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }


  // helpers for timestamps 
  String formatGroupDate(DateTime dt) {
    final now = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    if (isSameDay(dt, now)) return "Today";
    if (isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      return "Yesterday";
    }

    return "${dt.day.toString().padLeft(2, '0')} "
        "${_month(dt.month)} ${dt.year}";
  }

  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  String formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return "$h:$m";
}
}

class _Message {
  final String id;
  final String text;
  final bool fromMe;
  final bool isInvitation;
  final DateTime createdAt;
  bool? invitationStatus;

  _Message({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.createdAt,
    this.isInvitation = false,
    this.invitationStatus,
  });
}
