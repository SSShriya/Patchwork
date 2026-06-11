import 'package:drp/services/utils.dart';

import '../main.dart';
import 'package:drp/widgets/chat_section.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';
import '../services/event_service.dart';

class DMOverviewScreen extends StatefulWidget {
  const DMOverviewScreen({super.key});

  @override
  State<DMOverviewScreen> createState() => _DMOverviewScreenState();
}

class _DMOverviewScreenState extends State<DMOverviewScreen> with RouteAware {
  final _conversationService = ConversationService();
  final _eventService = EventService();
  List<ChatConversation> _conversations = [];
  bool isLoading = true;

  // For filtering events
  String? _selectedEventName;
  List<MapEntry<String, String>> _eventFilters = [];
  Map<String, ({String endDay, String endTime})> _eventEndTimes = {};
  Map<String, List<String>> _eventsInCommon = {};   // Map of otherUserId to list of eventNames

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Always unsubscribe to avoid memory leaks
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// Called when this screen is popped back to (e.g. user navigates back)
  @override
  void didPopNext() {
    _loadConversations(); // reload every time the screen is returned to
  }

  /// Called when this screen is first pushed onto the stack
  @override
  void didPush() {
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);
    final convos = await _conversationService.getConversations();

    final eventIds = convos
        .map((c) => c.eventId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final endTimes = await _conversationService.getEventEndTimes(eventIds);

    final myId = await loadUserId();

    // Map of otherUserId to all events in common
    final Map<String, List<String>> eventsInCommon = {};

    // Event filter chips
    final seen = <String>{};
    final filters = <MapEntry<String, String>>[];
    for (final chat in convos) {
      if (_isChatCurrent(chat) && seen.add(chat.eventId)) {
        filters.add(MapEntry(chat.eventId, chat.event));
        eventsInCommon[chat.otherUserId] = await _eventService.eventsInCommon(
          myId,
          chat.otherUserId,
        );
      }
    }

    setState(() {
      _conversations = convos;
      _eventEndTimes = endTimes;
      _eventFilters = filters;
      _eventsInCommon = eventsInCommon;
      isLoading = false;
    });
  }

  bool _isChatCurrent(ChatConversation chat) {
    final endTimeEntry = _eventEndTimes[chat.eventId];

    // If we have no end time data, default to treating it as current
    if (endTimeEntry == null) return true;

    final endDay = endTimeEntry.endDay;
    final endTime = endTimeEntry.endTime;

    if (endDay.isEmpty || endTime.isEmpty) return true;

    try {
      final endDateTime = DateTime.parse('$endDay $endTime');
      return DateTime.now().isBefore(endDateTime);
    } catch (_) {
      return true; // default to current if parsing fails
    }
  }

  /// Returns conversations that satisfy both the text search query
  /// and the currently selected event filter chip.
  List<ChatConversation> _applyFilters(List<ChatConversation> source) {
  return source.where((chat) {

    // --- Search filter ---
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = chat.name.toLowerCase().contains(query);

      // Get all event names for this chat's user, falling back to an empty list
      final userEvents = _eventsInCommon[chat.otherUserId] ?? [];

      // Match if any of the user's events contain the search query
      final eventMatch = userEvents.any(
        (eventName) => eventName.toLowerCase().contains(query),
      );

      if (!nameMatch && !eventMatch) return false;
    }

    // --- Event filter ---
    if (_selectedEventName != null) {
      // Get all event names for this chat's user
      final userEvents = _eventsInCommon[chat.otherUserId] ?? [];

      // Keep this chat only if any of their events match the selected event name
      final hasMatchingEvent = userEvents.any(
        (eventName) => eventName == _selectedEventName,
      );

      if (!hasMatchingEvent) return false;
    }

    return true;
  }).toList();
}

  @override
  Widget build(BuildContext context) {
    // 1. Initial generalized search filtering
    final filteredConversations = _applyFilters(_conversations);

    // 2. Separate Society Chats completely away from general user chats
    final filteredSocietyConvos = filteredConversations
        .where((chat) => chat.isSociety)
        .toList();

    // 3. Keep non-society matches and partition them by relevance
    final filteredCurrentConvos = filteredConversations
        .where((chat) => !chat.isSociety && _isChatCurrent(chat))
        .toList();

    final currentChatUserIds = filteredCurrentConvos
        .map((chat) => chat.otherUserId)
        .toSet();

    // Ensure the old conversations have no current user IDs
    final filteredOldConvos = filteredConversations
        .where(
          (chat) =>
              !chat.isSociety &&
              !_isChatCurrent(chat) &&
              !currentChatUserIds.contains(chat.otherUserId),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F6),
      appBar: AppBar(
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: const Color(0XFF222222),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            fontFamily: 'Lora',
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------- SEARCH BAR ----------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or event...',
                          hintStyle: const TextStyle(fontFamily: 'Montserrat'),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF4D5359),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Color(0xFF4D5359),
                                  ),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Color(0XBFFEFEFA),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // --- EVENT FILTER CHIPS -----------------
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildEventFilterRow(),
                    ),

                    // --- CONVERSATION SECTIONS ----------------
                    if (filteredConversations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Text(
                            'No conversations found matching criteria.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // Current Chats Section
                      if (filteredCurrentConvos.isNotEmpty)
                        ChatSection(
                          title: 'Current Chats',
                          conversations: filteredCurrentConvos,
                          eventsInCommon: _eventsInCommon,
                          onRefresh: _loadConversations,
                          currentChats: true,
                        ),

                      // Society Chats Section
                      if (filteredSocietyConvos.isNotEmpty)
                        ChatSection(
                          title: 'Contact a Committee Member',
                          conversations: filteredSocietyConvos,
                          eventsInCommon: _eventsInCommon,
                          onRefresh: _loadConversations,
                          currentChats: true,
                        ),

                      // Old Chats Section
                      if (filteredOldConvos.isNotEmpty)
                        ChatSection(
                          title: 'Old Chats',
                          conversations: filteredOldConvos,
                          eventsInCommon: _eventsInCommon,
                          onRefresh: _loadConversations,
                        ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEventFilterRow() {
    // Don't render the row at all if there are no events to filter by
    if (_eventFilters.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // "All" chip — clears the event filter
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: const Text('All', style: TextStyle(fontFamily: 'Bitter')),
              selected: _selectedEventName == null,
              onSelected: (_) => setState(() => _selectedEventName = null),
              selectedColor: const Color(0XFFFC89AC),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                fontFamily: 'Bitter',
                color: _selectedEventName == null
                    ? Colors.black
                    : Colors.grey[700],
                fontWeight: _selectedEventName == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),

          // One chip per unique event
          ..._eventFilters.map((entry) {
            final isSelected = _selectedEventName == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  entry.value,
                  style: TextStyle(fontFamily: 'Bitter'),
                ), // displays eventName
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedEventName = entry.value),
                selectedColor: const Color(0xFFFC89AC),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
