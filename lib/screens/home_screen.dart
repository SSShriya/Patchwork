import 'package:drp/services/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_card.dart';
import '../models/event_card.dart';
import '../services/match_service.dart';
import '../widgets/match_row.dart';
import 'match_profile_screen.dart';
import '../models/match_convo.dart';
import '../widgets/interactive_card.dart';
import '../screens/event_matches_screen.dart';
import '../services/event_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final _matchService = MatchService();
  final _eventService = EventService();
  List<MatchCard> _pendingMatches = [];
  List<EventCard> _interestedEvents = [];
  // List<MatchCard> _awaitingMatches = [];
  bool _loading = true;
  List<ChatConversation> conversations = [];
  // bool _notificationSeen = false;

  List<MatchCard> _mutualMatches = [];
  List<MatchCard> _awaitingMatches = [];
  Set<String> _seenNotificationIds = {}; // persisted

  static const _seenPrefsKey = 'seen_notification_ids';

  @override
  void initState() {
    super.initState();
    _loadSeenIds().then((_) => _loadMatches());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    try {
      final userId = await loadUserId();

      final matches = await _matchService.getPendingMatches(userId);

      final events = await _eventService.getInterestedEvents(userId);
      final awaiting = await _matchService.getAwaitingResponseMatches(userId);
      final mutual = await _matchService.getMutualMatches(userId);

      setState(() {
        _interestedEvents = events
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        // reusing the alr filtered event ids from getInterestedEvents
        final activeEventIds = _interestedEvents.map((e) => e.eventId).toSet();

        _pendingMatches = matches
            .where((m) => activeEventIds.contains(m.eventId))
            .toList();
        _awaitingMatches = awaiting
            .where((m) => activeEventIds.contains(m.eventId))
            .toList();
        _mutualMatches = mutual
            .where((m) => activeEventIds.contains(m.eventId))
            .toList();

        _loading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signup');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An issue has occurred: for your security, you have been logged out.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Called by UserProfileScreen via callback
  Future<void> _handleDecision(MatchCard card, bool accepted) async {
    await _matchService.recordDecision(card, accepted);
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
        builder: (_) => MatchProfileScreen(
          cards: groupCards,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
          onDecision: _handleDecision,
          onGoHome: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          },
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
    if (_interestedEvents.isEmpty) return {};

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
    final eventsWithMatches = _interestedEvents
        .where((e) => (groupedMatches[e.eventId]?.isNotEmpty ?? false))
        .toList(); // already sorted by date from _loadMatches

    final eventsWithoutMatches = _interestedEvents
        .where((e) => (groupedMatches[e.eventId]?.isEmpty ?? true))
        .toList(); // already sorted by date from _loadMatches

    return Scaffold(
      backgroundColor: const Color(0XFFF5F0F6),
      endDrawer: Drawer(
        backgroundColor: const Color(0xFFF5F0F6),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // -- New matches --
                Text(
                  'New Matches !!',
                  style: GoogleFonts.bitter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_mutualMatches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'No new matches yet',
                      style: GoogleFonts.merriweather(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  ..._mutualMatches.map(
                    (m) => _notifTile(
                      m,
                      isNew: !_seenNotificationIds.contains(
                        'mutual_${m.otherUserId}',
                      ),
                      subtitle: m.eventName,
                      badge: 'Matched',
                      badgeColor: const Color(0XFF84DCC6),
                      badgeTextColor: const Color(0XFF2A8C73),
                    ),
                  ),

                const Divider(height: 24),

                // -- Pending --
                Text(
                  'Waiting for their response...',
                  style: GoogleFonts.bitter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You liked them — waiting to hear back',
                  style: GoogleFonts.merriweather(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                if (_awaitingMatches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Text(
                        'No pending responses right now',
                        style: GoogleFonts.merriweather(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: _awaitingMatches
                          .map(
                            (m) => _notifTile(
                              m,
                              isNew: !_seenNotificationIds.contains(
                                'await_${m.otherUserId}',
                              ),
                              subtitle: m.eventName,
                              badge: 'Pending',
                              badgeColor: const Color(0XFFEFDD8D),
                              badgeTextColor: const Color.fromARGB(
                                255,
                                86,
                                66,
                                3,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      appBar: AppBar(
        title: Text(
          'Welcome Back!',
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: const Color(0XFF222222),
        actions: [
          Stack(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    final allCurrentIds = {
                      ..._mutualMatches.map((m) => 'mutual_${m.otherUserId}'),
                      ..._awaitingMatches.map((m) => 'await_${m.otherUserId}'),
                    };
                    setState(() => _seenNotificationIds = allCurrentIds);
                    _saveSeenIds();
                    Scaffold.of(ctx).openEndDrawer();
                  },
                ),
              ),
              if (_unseenIds.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 247, 101, 101),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_unseenIds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        automaticallyImplyLeading: false,
      ),

      body: RefreshIndicator(
        onRefresh: _loadMatches,
        color: const Color(0xFF84DCC6),
        child: ListView(
          // physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Upcoming Events",
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click to see event details and your existing friends!',
                    style: GoogleFonts.merriweather(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
                      builder: (_) => EventMatchesScreen(
                        allEvents: _interestedEvents,
                        event: _interestedEvents[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "People to Review",
                    style: GoogleFonts.lora(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Curated people who are also interested in your events!',
                    style: GoogleFonts.merriweather(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // one MatchRow per event
            // one MatchRow per event — with matches first, then without
            if (_pendingMatches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text("You've reviewed everyone!!")),
              )
            else ...[
              // ── Events WITH matches ──
              for (final event in eventsWithMatches)
                MatchRow(
                  cards: groupedMatches[event.eventId] ?? [],
                  eventLabel: event.title,
                  onTap: (i) {
                    final cards = groupedMatches[event.eventId] ?? [];
                    if (cards.isNotEmpty) _openProfile(cards[i]);
                  },
                ),

              // ── Events WITHOUT matches ──
              for (final event in eventsWithoutMatches)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.bitter(
                          fontSize: 18,
                          color: const Color(0XFF222222),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No potential matches yet, come back later',
                        style: GoogleFonts.merriweather(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
          ],
        ),
      ),
    );
  }

  // notif tile
  Widget _notifTile(
    MatchCard m, {
    required bool isNew,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: isNew
          ? BoxDecoration(
              color: const Color(0xFF84DCC6),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: m.imageUrl.isNotEmpty
              ? NetworkImage(m.imageUrl)
              : null,
          backgroundColor: const Color(0xFF84DCC6),
          child: m.imageUrl.isEmpty
              ? Text(
                  m.title.isNotEmpty ? m.title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              m.title,
              style: GoogleFonts.bitter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isNew) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.merriweather(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: GoogleFonts.merriweather(
              fontSize: 11,
              color: badgeTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // -- helpers for notifications --
  Future<void> _loadSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_seenPrefsKey) ?? [];
    setState(() => _seenNotificationIds = stored.toSet());
  }

  Future<void> _saveSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_seenPrefsKey, _seenNotificationIds.toList());
  }

  Set<String> get _unseenIds {
    final allCurrentIds = {
      ..._mutualMatches.map((m) => 'mutual_${m.otherUserId}'),
      ..._awaitingMatches.map((m) => 'await_${m.otherUserId}'),
    };
    return allCurrentIds.difference(_seenNotificationIds);
  }
}
