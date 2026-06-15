import 'package:drp/services/utils.dart';
import 'package:drp/tools/scalloped_clipper.dart';
import 'package:drp/tools/stitched_search_bar.dart';
import '../main.dart';
import 'package:drp/widgets/chat_section.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';
import '../services/event_service.dart';
import '../tools/sitched_divider.dart';

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
  String? _selectedEventId;
  List<MapEntry<String, String>> _eventFilters = [];
  Map<String, ({String endDay, String endTime})> _eventEndTimes = {};
  Map<String, List<MapEntry<String, String>>> _eventsInCommon = {};

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
    precacheImage(const AssetImage('assets/textures/bg_texture.jpg'), context);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadConversations();
  }

  @override
  void didPush() {
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);

    // Fetch both in parallel
    final results = await Future.wait([
      _conversationService.getConversations(),
      _conversationService.getSocietyConversations(), // ← NEW
    ]);

    final matchConvos = results[0];
    final societyConvos = results[1];

    // Merge, avoiding duplicates (in case a society also has a match row)
    final existingSocietyIds = matchConvos
        .where((c) => c.isSociety)
        .map((c) => c.otherUserId)
        .toSet();

    final dedupedSocietyConvos = societyConvos
        .where((c) => !existingSocietyIds.contains(c.otherUserId))
        .toList();

    final convos = [...matchConvos, ...dedupedSocietyConvos]; // ← merged

    final eventIds = convos
        .map((c) => c.eventId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final endTimes = await _conversationService.getEventEndTimes(eventIds);
    final myId = await loadUserId();

    final Map<String, List<MapEntry<String, String>>> eventsInCommon = {};

    final seenEventIds = <String>{};
    final seenUsers = <String>{};
    final filters = <MapEntry<String, String>>[];

    for (final chat in convos) {
      if (!_isChatCurrent(chat)) continue;

      if (chat.eventId.isNotEmpty && seenEventIds.add(chat.eventId)) {
        filters.add(MapEntry(chat.eventId, chat.event));
      }

      if (chat.isSociety) {
        if (chat.eventId.isNotEmpty) {
          (eventsInCommon[chat.otherUserId] ??= []).add(
            MapEntry(chat.eventId, chat.event),
          );
        }
      } else if (seenUsers.add(chat.otherUserId)) {
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

    if (endTimeEntry == null) return true;

    final endDay = endTimeEntry.endDay;
    final endTime = endTimeEntry.endTime;

    if (endDay.isEmpty || endTime.isEmpty) return true;

    try {
      final endDateTime = DateTime.parse('$endDay $endTime');
      return DateTime.now().isBefore(endDateTime);
    } catch (_) {
      return true;
    }
  }

  /// Sorts conversations so the most recently active appears first.
  /// Falls back to matchedAt for conversations with no messages.
  List<ChatConversation> _sortByRecent(List<ChatConversation> convos) {
    final sorted = List<ChatConversation>.from(convos);

    sorted.sort((a, b) {
      // Normalise everything to UTC before comparing
      final aTime = (a.lastMessageAt ?? a.matchedAt)?.toUtc();
      final bTime = (b.lastMessageAt ?? b.matchedAt)?.toUtc();

      if (aTime != null && bTime != null) return bTime.compareTo(aTime);
      if (aTime == null && bTime != null) return 1;
      if (aTime != null && bTime == null) return -1;
      return 0;
    });

    return sorted;
  }

  List<ChatConversation> _applyFilters(List<ChatConversation> source) {
    return source.where((chat) {
      // --- Search filter ---
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = chat.name.toLowerCase().contains(query);
        final userEvents = _eventsInCommon[chat.otherUserId] ?? [];
        final eventMatch = userEvents.any(
          (entry) => entry.value.toLowerCase().contains(query),
        );
        if (!nameMatch && !eventMatch) return false;
      }

      // --- Event filter ---
      if (_selectedEventId != null) {
        final userEvents = _eventsInCommon[chat.otherUserId] ?? [];
        final hasMatchingEvent = userEvents.any(
          (entry) => entry.key == _selectedEventId,
        );
        if (!hasMatchingEvent) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Apply search/event filters
    final filteredConversations = _applyFilters(_conversations);

    // 2. Separate and sort each section
    final filteredSocietyConvos = _sortByRecent(
      filteredConversations.where((chat) => chat.isSociety).toList(),
    );

    final filteredCurrentConvos = _sortByRecent(
      filteredConversations
          .where((chat) => !chat.isSociety && _isChatCurrent(chat))
          .toList(),
    );

    final currentChatUserIds = filteredCurrentConvos
        .map((chat) => chat.otherUserId)
        .toSet();

    final filteredOldConvos = _sortByRecent(
      filteredConversations
          .where(
            (chat) =>
                !chat.isSociety &&
                !_isChatCurrent(chat) &&
                !currentChatUserIds.contains(chat.otherUserId),
          )
          .toList(),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F0F6),
      ),
      child: Stack(
        children: [
          // Solid base colour first
          Positioned.fill(child: ColoredBox(color: const Color(0xFFF5F0F6))),

          // BG IMG
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/textures/bg_texture.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0xFFF5F0F6).withValues(alpha: 0.4),
                      BlendMode.multiply,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          Scaffold(
            // backgroundColor: const Color(0xFFF5F0F6),
            backgroundColor: Colors.transparent,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 10),
              child: ClipPath(
                clipper: ScallopedClipper(),
                child: AppBar(
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
                  flexibleSpace: Opacity(
                    opacity: 0.6,
                    child: Image(
                      image: AssetImage('assets/images/teal_gingham.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  centerTitle: true,
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
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              16.0,
                              16.0,
                              8.0,
                            ),
                            child: StitchedSearchBar(
                              hintText: 'Search by name or event...',
                              searchQuery: _searchQuery,
                              borderRadius: 24,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              onClear: () {
                                FocusScope.of(context).unfocus();
                                setState(() => _searchQuery = '');
                              },
                            ),
                            // child: TextField(
                            //   onChanged: (value) {
                            //     setState(() {
                            //       _searchQuery = value;
                            //     });
                            //   },
                            //   decoration: InputDecoration(
                            //     hintText: 'Search by name or event...',
                            //     hintStyle: const TextStyle(
                            //       fontFamily: 'Montserrat',
                            //     ),
                            //     prefixIcon: const Icon(
                            //       Icons.search,
                            //       color: Color(0xFF4D5359),
                            //     ),
                            //     suffixIcon: _searchQuery.isNotEmpty
                            //         ? IconButton(
                            //             icon: const Icon(
                            //               Icons.clear,
                            //               color: Color(0xFF4D5359),
                            //             ),
                            //             onPressed: () {
                            //               FocusScope.of(context).unfocus();
                            //               setState(() => _searchQuery = '');
                            //             },
                            //           )
                            //         : null,
                            //     filled: true,
                            //     fillColor: Color(0XBFFEFEFA),
                            //     contentPadding: const EdgeInsets.symmetric(
                            //       vertical: 0,
                            //     ),
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(24),
                            //       borderSide: BorderSide.none,
                            //     ),
                            //   ),
                            // ),
                          ),

                          // --- EVENT FILTER CHIPS -----------------
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildEventFilterRow(),
                          ),

                          // --- CONVERSATION SECTIONS ----------------
                          if (filteredConversations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40.0,
                              ),
                              child: Center(
                                child: Text(
                                  'Match with a friend to start a conversation!',
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

                            // Divider between Current Chats and Society Chats
                            if (filteredCurrentConvos.isNotEmpty &&
                                filteredSocietyConvos.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: StitchedDivider(
                                  color: Color(0x8FCD5C5C),
                                ),
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

                            // Divider between Society Chats and Old Chats
                            if (filteredSocietyConvos.isNotEmpty &&
                                filteredOldConvos.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: StitchedDivider(),
                              ),

                            // Edge case: divider if Current exists but Society doesn't, before Old
                            if (filteredCurrentConvos.isNotEmpty &&
                                filteredSocietyConvos.isEmpty &&
                                filteredOldConvos.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: StitchedDivider(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEventFilterRow() {
    if (_eventFilters.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: const Text('All', style: TextStyle(fontFamily: 'Bitter')),
              selected: _selectedEventId == null,
              onSelected: (_) => setState(() => _selectedEventId = null),
              selectedColor: const Color(0XFFFC89AC),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                fontFamily: 'Bitter',
                color: _selectedEventId == null
                    ? Colors.black
                    : Colors.grey[700],
                fontWeight: _selectedEventId == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),

          ..._eventFilters.map((entry) {
            final isSelected = _selectedEventId == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  entry.value,
                  style: const TextStyle(fontFamily: 'Bitter'),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedEventId = entry.key),
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
