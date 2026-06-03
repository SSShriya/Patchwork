import 'package:drp/widgets/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import '../models/event_card.dart';
import '../services/event_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/event_detail_card.dart';
import 'event_profile_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _eventService = EventService();
  late TextEditingController _searchController;
  List<EventCard> _allEvents = [];
  List<EventCard> _filteredEvents = [];
  bool _loading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterEvents);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _eventService.getAllEvents();
    setState(() {
      _allEvents = events;
      _filteredEvents = events;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents
          .where(
            (event) =>
                event.title.toLowerCase().contains(query) ||
                event.subtitle.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  void _openEventSummary(EventCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventProfileScreen(card: card),
      ),
    );
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
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

                // Events Section
                if (_filteredEvents.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Events',
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isGridView ? Icons.view_list : Icons.grid_view,
                          ),
                          onPressed: () =>
                              setState(() => _isGridView = !_isGridView),
                        ),
                      ],
                    ),
                  ),
                  _isGridView
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width > 1200
                                ? 5
                                : width > 900
                                ? 4
                                : width > 600
                                ? 3
                                : 2;
                            // final aspectRatio = width > 900
                            //     ? 0.85
                            //     : width > 600
                            //     ? 0.95
                            //     : 0.75;
                            // final cardWidth =
                            //     (width - 12 * (crossAxisCount + 1)) /
                                crossAxisCount;
                            // final cardHeight = cardWidth * aspectRatio;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (_, i) => EventDetailCard(
                                card: _filteredEvents[i],
                                onTap: () => _openEventSummary(_filteredEvents[i]),
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    // childAspectRatio: cardWidth / cardHeight,
                                    childAspectRatio: 1.0,
                                    mainAxisExtent: 230,
                                  ),
                            );
                          },
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              height: 250,
                              child: EventDetailCard(
                                card: _filteredEvents[i],
                                onTap: () => _openEventSummary(_filteredEvents[i]),
                              ),
                            ),
                          ),
                        ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events found',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 1),
    );
  }
}
