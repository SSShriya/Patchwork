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
      _interestedEvents = events;
    });
  }

  // Called by UserProfileScreen via callback
  void _handleDecision(MatchCard card, bool accepted) {
    setState(() => _pendingMatches.remove(card));
    // Fire-and-forget — saves to Supabase in background
    _matchService.recordDecision(card.id, accepted);
  }

  void _openProfile(MatchCard card) {
    final groupCards = _pendingMatches
        .where((c) => c.event == card.event)
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
      map.putIfAbsent(card.event, () => []).add(card);
    }
    return map;
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
        title: const Text('Welcome Back!'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Confirmed Matches by Event',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 180,
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Matches to Review',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // one MatchRow per event
          if (groupedMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text("You've reviewed everyone!!")),
            )
          else
            for (final entry in groupedMatches.entries)
              MatchRow(
                cards: entry.value,
                eventLabel: entry.key,
                onTap: (i) => _openProfile(entry.value[i]),
              ),

          const Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
        ],
      ),

      bottomNavigationBar: AppNavigationBar(),
    );
  }
}
