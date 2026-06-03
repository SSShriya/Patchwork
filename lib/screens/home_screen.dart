import 'package:flutter/material.dart';
import '../models/match_card.dart';
import '../models/event_card.dart';
import '../services/match_service.dart';
import '../widgets/match_row.dart';
import '../widgets/app_navigation_bar.dart';
import 'user_profile_screen.dart';
import '../models/match_convo.dart';
import '../widgets/interactive_card.dart';
import '../screens/event_matches_screen.dart';
import '../services/event_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _matchService = MatchService();
  final _eventService = EventService();
  List<MatchCard> _pendingMatches = [];
  List<EventCard> _interestedEvents = [];
  bool _loading = true;
  List<ChatConversation> conversations = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    final matches = await _matchService.getPendingMatches();
    final events = await _eventService.getInterestedEvents();
    setState(() {
      _pendingMatches = matches;
      _loading = false;
      _interestedEvents = events
        ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    });
  }

  // Called by UserProfileScreen via callback
  Future<void> _handleDecision(MatchCard card, bool accepted) async {
    await _matchService.recordDecision(card.id, accepted);
    setState(() => _pendingMatches.remove(card));
  }

  void _openProfile(MatchCard card) {
    final groupCards = _pendingMatches
        .where((c) => c.eventId == card.eventId)
        .toList();
    final initialIndex = groupCards.indexOf(card);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          cards: groupCards,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
          onDecision: _handleDecision,
        ),
      ),
    );
  }

  // group _pendingMatches by event name
  Map<String, List<MatchCard>> get _matchesByEvent {
    final map = <String, List<MatchCard>>{};
    for (final card in _pendingMatches) {
      map.putIfAbsent(card.eventId, () => []).add(card);
    }

    // sort by date time
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) {
        final aEvent = _interestedEvents.firstWhere(
          (e) => e.eventId == a.key,
          orElse: () => _interestedEvents.first,
        );
        final bEvent = _interestedEvents.firstWhere(
          (e) => e.eventId == b.key,
          orElse: () => _interestedEvents.first,
        );
        return aEvent.startDateTime.compareTo(bEvent.startDateTime);
      }),
    );

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupedMatches = _matchesByEvent;

    return Scaffold(
      backgroundColor: const Color(0XFFF5F0F6),
      appBar: AppBar(
        title: Text('Welcome Back!', style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 25)),
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: const Color(0XFF222222),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches, // pull fresh data anytime
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Your Upcoming Events',
              style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _interestedEvents.length,
              itemBuilder: (_, i) => InteractiveCard(
                card: _interestedEvents[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EventMatchesScreen(event: _interestedEvents[i]),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Matches to Review',
              style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // one MatchRow per event
          if (_pendingMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text("You've reviewed everyone!!")),
            )
          else
            for (final event in _interestedEvents)
              (groupedMatches[event.eventId]?.isEmpty ?? true)
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.bitter(fontSize: 18, color: const Color.fromARGB(255, 89, 79, 79))
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No matches yet, come back later',
                          style: GoogleFonts.merriweather(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
              : MatchRow(
                cards: groupedMatches[event.eventId] ?? [],
                eventLabel: event.title,
                onTap: (i) {
                  final cards = groupedMatches[event.eventId] ?? [];
                  if (cards.isNotEmpty) {
                    _openProfile(cards[i]);
                  }
                },
              ),

          const Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
        ],
      ),

      bottomNavigationBar: AppNavigationBar(),
    );
  }
}
