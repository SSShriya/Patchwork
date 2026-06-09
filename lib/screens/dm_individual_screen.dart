import 'dart:async';
import 'package:drp/models/dm_message.dart';
import 'package:drp/services/utils.dart';
import 'package:drp/widgets/dm_chat_header.dart';
import 'package:drp/widgets/dm_input_bar.dart';
import 'package:drp/widgets/dm_invitation_card.dart';
import 'package:drp/widgets/dm_meeting_popup.dart';
import 'package:drp/widgets/dm_pinned_banner.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';

class DMScreen extends StatefulWidget {
  final ChatConversation chat;
  final bool suggestMeeting;

  const DMScreen({super.key, required this.chat, this.suggestMeeting = false});

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  // ── Controllers & services ──────────────────
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _conversationService = ConversationService();

  // ── State ───────────────────────────────────
  late final String _myUserId;
  List<DmMessage> _messages = [];
  final List<GlobalKey> _messageKeys = [];
  bool _isLoading = true;
  bool _isReady = false;
  Timer? _pollingTimer;

  // ── Constants ───────────────────────────────
  static const _primaryColor = Color(0xFF8789C0);

  // ── Lifecycle ───────────────────────────────

  @override
  void initState() {
    super.initState();
    _initChatAndStartPolling();
    if (widget.suggestMeeting) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _suggestMeeting());
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Initialisation ──────────────────────────

  Future<void> _initChatAndStartPolling() async {
    _myUserId = await loadUserId();
    await _loadMessages(forceScroll: true);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _loadMessages(),
    );
  }

  // ── Data loading ────────────────────────────

  Future<void> _loadMessages({bool forceScroll = false}) async {
    try {
      final rows = await _conversationService.getMessages(
        _myUserId,
        widget.chat.otherUserId,
      );

      final fresh = rows.map((row) {
        final content = (row['content'] ?? '') as String;
        final isInvite = content.startsWith(invitePrefix);
        return DmMessage(
          id: row['message_id']?.toString() ?? '',
          text: content,
          fromMe: row['sender_id'] == _myUserId,
          createdAt: DateTime.parse(row['created_at'] as String),
          isInvitation: isInvite,
          invitationStatus: isInvite ? row['invitation_status'] as bool? : null,
          lastEditedBy: row['last_edited_by'] as String?,
        );
      }).toList();

      final hasChanges =
          fresh.length != _messages.length ||
          fresh.any((f) {
            final existing = _messages.firstWhere(
              (m) => m.id == f.id,
              orElse: () => f,
            );
            return existing.invitationStatus != f.invitationStatus;
          });

      if (!mounted) return;

      setState(() {
        _messages = fresh;
        _isLoading = false;
        while (_messageKeys.length < _messages.length) {
          _messageKeys.add(GlobalKey());
        }
        while (_messageKeys.length > _messages.length) {
          _messageKeys.removeLast();
        }
      });

      if (forceScroll || hasChanges) {
        _scrollToBottom();
      } else if (!_isReady) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint('_loadMessages error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReady = true;
        });
      }
    }
  }

  // ── Scrolling ───────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      if (!_isReady && mounted) setState(() => _isReady = true);
    });
  }

  void _scrollToMessage(int index) {
    if (index < 0 || index >= _messageKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Path 1: widget is mounted — ensureVisible handles it precisely
      final ctx = _messageKeys[index].currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
        return;
      }

      // Path 2: widget is off-screen — proportional jump to force mount,
      // then ensureVisible corrects the final position
      final estimated =
          (index / _messages.length) *
          _scrollController.position.maxScrollExtent;

      _scrollController.jumpTo(
        estimated.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final mountedCtx = _messageKeys[index].currentContext;
      if (mountedCtx != null && mountedCtx.mounted) {
        await Scrollable.ensureVisible(
          mountedCtx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  // ── Actions ─────────────────────────────────

  void _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final id = await _conversationService.recordMessage(
      text,
      _myUserId,
      widget.chat.otherUserId,
    );

    setState(() {
      _messages.add(
        DmMessage(id: id, text: text, fromMe: true, createdAt: DateTime.now()),
      );
      _messageKeys.add(GlobalKey());
    });
    _scrollToBottom();
  }

  void _suggestMeeting() async {
    final result = await showDialog<Map>(
      context: context,
      builder: (_) => const DMMeetingPopup(),
    );
    if (result == null) return;

    final payload = buildInvitePayload(result);
    final id = await _conversationService.recordMessage(
      payload,
      _myUserId,
      widget.chat.otherUserId,
    );

    setState(() {
      _messages.add(
        DmMessage(
          id: id,
          text: payload,
          fromMe: true,
          isInvitation: true,
          createdAt: DateTime.now(),
        ),
      );
      _messageKeys.add(GlobalKey());
    });
    _scrollToBottom();
  }

  void _editMeeting(int index) async {
    final msg = _messages[index];
    final parsed = parseInvitePayload(msg.text);

    final result = await showDialog<Map>(
      context: context,
      builder: (_) => DMMeetingPopup(
        initialDate: parsed.date == 'Not specified' ? null : parsed.date,
        initialTime: parsed.time == 'Not specified' ? null : parsed.time,
        initialLocation: parsed.location == 'Not specified'
            ? null
            : parsed.location,
      ),
    );
    if (result == null) return;

    final payload = buildInvitePayload(result);
    await _conversationService.updateInvitationContent(
      msg.id,
      payload,
      _myUserId,
    );

    setState(() {
      _messages[index] = DmMessage(
        id: msg.id,
        text: payload,
        fromMe: msg.fromMe,
        isInvitation: true,
        createdAt: DateTime.now(),
        lastEditedBy: _myUserId,
      );
    });
  }

  void _handleInvitationResponse(int index, bool accepted) async {
    setState(() => _messages[index].invitationStatus = accepted);
    try {
      await _conversationService.updateInvitationStatus(
        _messages[index].id,
        accepted,
      );
    } catch (e) {
      debugPrint('_handleInvitationResponse error: $e');
    }
  }

  void _showHints() {
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
      builder: (ctx) => AlertDialog(
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
                    Navigator.pop(ctx);
                    _textController.text = prompt;
                    _send();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84DCC6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF84DCC6)),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BACK'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: Scaffold(
        appBar: DmChatHeader(
          chat: widget.chat,
          onSuggestMeeting: _suggestMeeting,
          onShowHints: _showHints,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimatedOpacity(
                opacity: _isReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Column(
                  children: [
                    DmPinnedBanner(
                      messages: _messages,
                      onTap: _scrollToMessage,
                    ),
                    Expanded(child: _buildMessageList()),
                    DmInputBar(
                      controller: _textController,
                      recipientName: widget.chat.name,
                      onSend: _send,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Message list ─────────────────────────────

  Widget _buildMessageList() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        const SizedBox(height: 16),

        if (widget.chat.event.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEC0C6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.chat.name}'s Interests:",
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '★ ',
                          style: TextStyle(fontSize: 13, color: Colors.black),
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

        ..._buildGroupedMessages(),
      ],
    );
  }

  List<Widget> _buildGroupedMessages() {
    final widgets = <Widget>[];

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final prev = i > 0 ? _messages[i - 1] : null;

      // Date header
      if (prev == null ||
          formatGroupDate(prev.createdAt) != formatGroupDate(msg.createdAt)) {
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

      final Widget content = msg.isInvitation
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DmInvitationCard(
                msg: msg,
                index: i,
                myUserId: _myUserId,
                onEdit: _editMeeting,
                onRespond: _handleInvitationResponse,
              ),
            )
          : Padding(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: msg.fromMe
                            ? _primaryColor
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(msg.fromMe ? 16 : 0),
                          bottomRight: Radius.circular(msg.fromMe ? 0 : 16),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.fromMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTime(msg.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );

      widgets.add(KeyedSubtree(key: _messageKeys[i], child: content));
    }

    return widgets;
  }
}
