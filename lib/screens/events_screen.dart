import 'package:drp/models/match_convo.dart';
import 'package:drp/widgets/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import '../models/event_card.dart';
import '../widgets/interactive_card.dart';

class EventsScreen extends StatefulWidget {
  final List<EventCard> recommendedEvents;
  final List<ChatConversation> conversations;

  const EventsScreen({
    super.key,
    required this.recommendedEvents,
    required this.conversations,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late TextEditingController _searchController;
  List<EventCard> _filteredEvents = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredEvents = widget.recommendedEvents;
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = widget.recommendedEvents
          .where(
            (event) =>
                event.title.toLowerCase().contains(query) ||
                event.subtitle.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F6),
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: const Color(0XFF222222),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0XFF84DCC6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0XFF84DCC6),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0XFF84DCC6),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Recommended Events Section
          if (_filteredEvents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Recommended Events',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filteredEvents.length,
                itemBuilder: (_, i) => InteractiveCard(
                  card: _filteredEvents[i],
                  onTap: () {
                    // Handle event tap
                  },
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No events found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        conversations: widget.conversations,
        recommendedEvents: widget.recommendedEvents,
      ),
    );
  }
}
