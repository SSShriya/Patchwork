import 'dart:async';
import 'package:drp/services/utils.dart';
import 'package:drp/widgets/dm_meeting_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:intl/intl.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';
import '../widgets/user_profile_card.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────

class _Message {
  final String id;
  final String text;
  final bool fromMe;
  final bool isInvitation;
  final DateTime createdAt;
  final String? lastEditedBy;
  bool? invitationStatus;

  _Message({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.createdAt,
    this.isInvitation = false,
    this.invitationStatus,
    this.lastEditedBy,
  });
}

// ─────────────────────────────────────────────
// Tracked message widget
// Records its global Y offset once rendered so
// we can scroll to it even when off-screen.
// ─────────────────────────────────────────────

class _TrackedMessage extends StatefulWidget {
  final GlobalKey messageKey;
  final Widget child;
  final void Function(double globalY) onOffset;

  const _TrackedMessage({
    required this.messageKey,
    required this.child,
    required this.onOffset,
  });

  @override
  State<_TrackedMessage> createState() => _TrackedMessageState();
}

class _TrackedMessageState extends State<_TrackedMessage> {
  void _recordOffset() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;

      final scrollable = Scrollable.of(context);
      final viewportBox = scrollable.context.findRenderObject() as RenderBox?;
      if (viewportBox == null) return;

      final offsetInViewport = box
          .localToGlobal(Offset.zero, ancestor: viewportBox)
          .dy;
      final scrollOffset = scrollable.position.pixels + offsetInViewport;

      widget.onOffset(scrollOffset);
    });
  }

  @override
  void initState() {
    super.initState();
    _recordOffset();
  }

  @override
  void didUpdateWidget(_TrackedMessage old) {
    super.didUpdateWidget(old);
    _recordOffset(); // Re-record if widget was rebuilt in place
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: widget.messageKey, child: widget.child);
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

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
  List<_Message> _messages = [];
  final List<GlobalKey> _messageKeys = [];
  bool _isLoading = true;
  bool _isReady = false;
  Timer? _pollingTimer;

  // ── Constants ───────────────────────────────
  static const _primaryColor = Color(0xFF8789C0);
  static const _accentColor = Color(0xFF84DCC6);
  static const _accentDark = Color(0xFF409A83);
  static const _invitePrefix = 'INVITATION_DATA:';

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
        final isInvite = content.startsWith(_invitePrefix);
        return _Message(
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

      // Path 2: widget is off-screen — jump to proportional estimate
      // to force it to mount, then ensureVisible corrects the position
      final estimated =
          (index / _messages.length) *
          _scrollController.position.maxScrollExtent;

      _scrollController.jumpTo(
        estimated.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
      );

      // Wait two frames for layout and paint to complete
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final mountedCtx = _messageKeys[index].currentContext;
      if (mountedCtx != null) {
        await Scrollable.ensureVisible(
          mountedCtx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  // ── Invitation payload helpers ───────────────

  /// Builds the raw INVITATION_DATA string from a result map.
  String _buildInvitePayload(Map result) =>
      '$_invitePrefix{'
      '"date":"${result['date']}",'
      '"time":"${result['time']}",'
      '"location":"${result['location'] ?? ''}"'
      '}';

  /// Extracts date/time/location strings from a raw invite payload.
  ({String date, String time, String location}) _parseInvitePayload(
    String text,
  ) {
    final data = text.replaceFirst(_invitePrefix, '');
    String pick(RegExp re) {
      final m = re.firstMatch(data);
      return m != null ? m.group(1)! : 'Not specified';
    }

    final loc = pick(RegExp(r'"location":"([^"]*)"'));
    return (
      date: pick(RegExp(r'"date":"([^"]+)"')),
      time: pick(RegExp(r'"time":"([^"]+)"')),
      location: loc.isEmpty ? 'Not specified' : loc,
    );
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
        _Message(id: id, text: text, fromMe: true, createdAt: DateTime.now()),
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

    final payload = _buildInvitePayload(result);
    final id = await _conversationService.recordMessage(
      payload,
      _myUserId,
      widget.chat.otherUserId,
    );

    setState(() {
      _messages.add(
        _Message(
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
    final parsed = _parseInvitePayload(msg.text);

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

    final payload = _buildInvitePayload(result);
    await _conversationService.updateInvitationContent(
      msg.id,
      payload,
      _myUserId,
    );

    setState(() {
      _messages[index] = _Message(
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
                      color: _accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor),
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

  // ── Date / time formatters ───────────────────

  String _formatGroupDate(DateTime dt) {
    final now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (sameDay(dt, now)) return 'Today';
    if (sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDate(String raw) {
    try {
      return DateFormat('EEE, MMM d yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
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
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimatedOpacity(
                opacity: _isReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Column(
                  children: [
                    _buildPinnedInviteBanner(),
                    Expanded(child: _buildMessageList()),
                    _buildInputBar(),
                  ],
                ),
              ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _accentColor,
      foregroundColor: Colors.white,
      title: GestureDetector(
        onTap: () {
          final card = widget.chat.matchCard;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  title: Text(card.title),
                ),
                body: UserProfileCard(card: card, accepted: true),
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
              img: (widget.chat.imageUrl?.isNotEmpty ?? false)
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
          iconSize: 36,
          tooltip:
              'Suggest a time/place to meet ${widget.chat.name} before ${widget.chat.event}!',
          onPressed: _suggestMeeting,
        ),
        IconButton(
          icon: const Icon(Icons.lightbulb_outline),
          iconSize: 36,
          tooltip: 'Prompts to help you chat with ${widget.chat.name}',
          onPressed: _showHints,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        const SizedBox(height: 16),

        // Event banner
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

        // Interests card
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

        // Messages with date headers
        ..._buildGroupedMessages(),
      ],
    );
  }

  /// Builds message bubbles interleaved with date-group headers.
  List<Widget> _buildGroupedMessages() {
    final widgets = <Widget>[];

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final prev = i > 0 ? _messages[i - 1] : null;

      // Date header
      if (prev == null ||
          _formatGroupDate(prev.createdAt) != _formatGroupDate(msg.createdAt)) {
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
                _formatGroupDate(msg.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
        );
      }

      // Message bubble or invitation card, both tracked for scroll
      final Widget content = msg.isInvitation
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInvitationBox(msg, i),
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
                      _formatTime(msg.createdAt),
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

  Widget _buildInvitationBox(_Message msg, int index) {
    final parsed = _parseInvitePayload(msg.text);
    final isPending = msg.invitationStatus == null;
    final lastEditedByMe = msg.lastEditedBy == _myUserId;
    final shouldShowButtons =
        !lastEditedByMe &&
        (msg.lastEditedBy != null || (!msg.fromMe && msg.lastEditedBy == null));

    return Align(
      alignment: msg.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryColor, width: 1.5),
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: const BoxDecoration(
                color: _primaryColor,
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

            // Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📅 Date: ${_formatDate(parsed.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⏰ Time: ${parsed.time}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 Location: ${parsed.location}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Divider(height: 16),

                  if (isPending) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _editMeeting(index),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (shouldShowButtons)
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
                                backgroundColor: _accentColor,
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
                      )
                    else
                      const Center(
                        child: Text(
                          'Waiting for reply...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ] else
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: msg.invitationStatus == true
                              ? _accentColor.withValues(alpha: 0.2)
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
                                ? _accentDark
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedInviteBanner() {
    final index = _messages.lastIndexWhere(
      (m) => m.isInvitation && m.invitationStatus != false,
    );
    if (index == -1) return const SizedBox.shrink();

    final msg = _messages[index];
    final parsed = _parseInvitePayload(msg.text);

    final (statusText, statusColor) = switch (msg.invitationStatus) {
      true => ('Accepted ✓', _accentDark),
      false => ('Declined ✕', Colors.red),
      _ => ('Pending', Colors.orange),
    };

    return GestureDetector(
      onTap: () => _scrollToMessage(index),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, size: 16, color: _primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pinned Meeting',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📅 ${_formatDate(parsed.date)}  ⏰ ${parsed.time}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
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
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _accentColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
