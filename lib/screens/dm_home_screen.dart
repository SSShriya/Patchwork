import 'package:drp/widgets/chat_section.dart';
import 'package:flutter/material.dart';
import '../models/match_convo.dart';
import '../services/conversation_service.dart';

class DMOverviewScreen extends StatefulWidget {
  const DMOverviewScreen({super.key});

  @override
  State<DMOverviewScreen> createState() => _DMOverviewScreenState();
}

class _DMOverviewScreenState extends State<DMOverviewScreen> {
  final _conversationService = ConversationService();
  List<ChatConversation> _conversations = [];
  bool isLoading = true;

  // For filtering events
  String? _selectedEventId; 
  List<MapEntry<String, String>> _eventFilters = [];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);
    final convos = await _conversationService.getConversations();

    // Derive (eventId, eventName) pairs from conversations
    final seen = <String>{}; 
    final filters = <MapEntry<String, String>>[]; 

    for (final chat in convos) {
      if (seen.add(chat.eventId)) {
        filters.add(MapEntry(chat.eventId, chat.event)); 
      }
    }

    setState(() {
      _conversations = convos;
      _eventFilters = filters; 
      isLoading = false;
    });
  }

  /// Returns conversations that satisfy both the text search query
  /// and the currently selected event filter chip.
  List<ChatConversation> _applyFilters(List<ChatConversation> source) {
    return source.where((chat) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = chat.name.toLowerCase().contains(query);
        final interestMatch = chat.interests
            .any((i) => i.toLowerCase().contains(query));
        if (!nameMatch && !interestMatch) return false;
      }

      // --- Event filter ---
      // If no chip is selected, show everything
      if (_selectedEventId != null && chat.eventId != _selectedEventId) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initial generalized search filtering
    final filteredConversations = _applyFilters(_conversations);

    // 2. Separate Society Chats completely away from general user chats
    // final filteredSocietyConvos = filteredConversations
    //     .where((chat) => chat.isSociety)
    //     .toList();

    // 3. Keep non-society matches and partition them strictly by activity metrics
    final filteredNewConvos = filteredConversations
        .where((chat) => !chat.isSociety && chat.numMessages <= 0)
        .toList();

    final filteredOldConvos = filteredConversations
        .where((chat) => !chat.isSociety && chat.numMessages > 0)
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
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
                          hintText: 'Search by name or interest...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      )
                    else ...[
                      // New Chats Section
                      if (filteredNewConvos.isNotEmpty)
                        ChatSection(
                          title: 'New Chats',
                          conversations: filteredNewConvos,
                          onRefresh: _loadConversations,
                        ),
                        
                      // Existing Chats Section
                      if (filteredOldConvos.isNotEmpty)
                        ChatSection(
                          title: 'Existing Chats',
                          conversations: filteredOldConvos,
                          onRefresh: _loadConversations,
                        ),

                      // Newly Added: Society Chats Section
                      // if (filteredSocietyConvos.isNotEmpty)
                      //   ChatSection(
                      //     title: 'Society Chats',
                      //     conversations: [],
                      //     onRefresh: _loadConversations,
                      //   ),
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
              label: const Text('All'),
              selected: _selectedEventId == null,
              onSelected: (_) => setState(() => _selectedEventId = null),
              selectedColor: const Color(0xFF84DCC6),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: _selectedEventId == null ? Colors.black : Colors.grey[700],
                fontWeight: _selectedEventId == null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),

          // One chip per unique event
          ..._eventFilters.map((entry) {
            final isSelected = _selectedEventId == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(entry.value),   // displays eventName
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedEventId = entry.key),
                selectedColor: const Color(0xFF84DCC6),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[700],
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}