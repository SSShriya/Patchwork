import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://fvxsvmpocsmhyhimollx.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2eHN2bXBvY3NtaHloaW1vbGx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NjYxMTAsImV4cCI6MjA5NTU0MjExMH0.2gIPw5mBVPMFvxIeWAKb6XRqrr4i_eSS-p8CqY_s16Y';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

// -- MODElS --

class MatchCard extends BaseCard {
  final String id; // from Supabase
  @override final String title;
  @override final String subtitle;
  final String course;
  final String bio;
  final String event;
  final String group;

  const MatchCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.course,
    required this.bio,
    required this.event,
    required this.group,
  });

  factory MatchCard.fromJson(Map<String, dynamic> json) => MatchCard(
        id: json['id'],
        title: json['name'],
        subtitle: json['university'],
        course: json['course'],
        bio: json['bio'],
        event: json['event'],
        group: json['event_group'],
      );

  // So InteractiveCard still works
  String get name => title;
  IconData get icon => Icons.person;
  Color get color => const Color(0XFFEEC0C6);
}

// -- Supabase service --
class MatchService {
  // Fetch all matches that haven't been decided yet
  Future<List<MatchCard>> getPendingMatches() async {
    // Get IDs of already-decided matches
    final decided = await supabase.from('decisions').select('match_id');
    final decidedIds = (decided as List).map((d) => d['match_id'] as String).toList();

    // Fetch matches not in that list
    var query = supabase.from('potential_matches').select();
    final rows = decidedIds.isEmpty
        ? await query
        : await query.not('id', 'in', decidedIds);

    return (rows as List).map((r) => MatchCard.fromJson(r)).toList();
  }

  // Record accept/reject — this is what gets saved to Supabase
  Future<void> recordDecision(String matchId, bool accepted) async {
    await supabase.from('decisions').insert({
      'match_id': matchId,
      'accepted': accepted,
    });
    await supabase.from('potential_matches').delete().eq('id', matchId);
  }

  // Fetch accepted matches (for a future "Accepted" screen)
  Future<List<MatchCard>> getAcceptedMatches() async {
    final rows = await supabase
        .from('decisions')
        .select('match_id, matches(*)')
        .eq('accepted', true);

    return (rows as List)
        .map((r) => MatchCard.fromJson(r['matches']))
        .toList();
  }
}

// -- Home screen --

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MatchService();
  List<MatchCard> _pendingMatches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _loading = true);
    final matches = await _service.getPendingMatches();
    setState(() {
      _pendingMatches = matches;
      _loading = false;
    });
  }

  // Called by UserProfileScreen via callback
  void _handleDecision(MatchCard card, bool accepted) {
    setState(() => _pendingMatches.remove(card));
    // Fire-and-forget — saves to Supabase in background
    _service.recordDecision(card.id, accepted);
  }

  void _openProfile(MatchCard card) {
    final groupCards = _pendingMatches.where((c) => c.group == card.group).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          cards: groupCards,
          initialIndex: groupCards.indexOf(card),
          onDecision: _handleDecision,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final choirCards = _pendingMatches.where((c) => c.group == 'choir').toList();
    final improvCards = _pendingMatches.where((c) => c.group == 'improv').toList();

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
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Recommended Events',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: recCards.length,
                itemBuilder: (_, i) =>
                    InteractiveCard(card: recCards[i], onTap: () {}),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text('Matches',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            if (choirCards.isNotEmpty)
              MatchRow(
                cards: choirCards,
                eventLabel: 'Choir Concert - Music Society',
                onTap: (i) => _openProfile(choirCards[i]),
              ),
            if (improvCards.isNotEmpty)
              MatchRow(
                cards: improvCards,
                eventLabel: 'Taster Session - Improv Society',
                onTap: (i) => _openProfile(improvCards[i]),
              ),
            if (choirCards.isEmpty && improvCards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text("You've reviewed everyone! 🎉")),
              ),
            const Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 12)),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(),
    );
  }
}

// -- user profile screen --
class UserProfileScreen extends StatefulWidget {
  final List<MatchCard> cards;
  final int initialIndex;
  final void Function(MatchCard, bool) onDecision;

  const UserProfileScreen({
    super.key,
    required this.cards,
    required this.initialIndex,
    required this.onDecision,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late List<MatchCard> _cards;
  late int _index;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.cards);
    _index = widget.initialIndex;
  }

  MatchCard get _current => _cards[_index];

  void _decide(bool accepted) {
    final card = _current;
    widget.onDecision(card, accepted); // → saves to Supabase, removes from HomeScreen
    setState(() {
      _cards.remove(card);
      if (_cards.isEmpty) { Navigator.pop(context); return; }
      if (_index >= _cards.length) _index = _cards.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(_current.title),
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0XFF8789C0),
                child: Text(_current.title[0],
                    style: const TextStyle(fontSize: 32, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_current.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${_current.course} at ${_current.subtitle}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ]),
            ]),
            const SizedBox(height: 16),
            Text(_current.bio, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text('Interested in:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_current.event,
                style: const TextStyle(fontSize: 16, color: Colors.deepPurple)),
            const Spacer(),
            Center(
              child: Text('${_index + 1} / ${_cards.length}',
                  style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                onPressed: _index > 0 ? () => setState(() => _index--) : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(80, 50)),
                onPressed: () => _decide(false),
                child: const Text('✕'),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(80, 50)),
                onPressed: () => _decide(true),
                child: const Text('✓'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _index < _cards.length - 1
                    ? () => setState(() => _index++)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

abstract class BaseCard {
  const BaseCard();

  String get title;
  String get subtitle;
  IconData get icon;
  Color get color;
}

// dummy cards
class AppCard extends BaseCard {
  @override final String title;
  @override final String subtitle;
  @override final IconData icon;
  @override final Color color;

  const AppCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const recCards = [
   AppCard(title: 'Cookie Making', subtitle: 'Baking Society', icon: Icons.cloud, color: Color(0XFFFED766)),
   AppCard(title: 'Fight Club', subtitle: 'Boxing Society', icon: Icons.cloud, color: Color(0XFFFED766)),
   AppCard(title: 'Listening Party', subtitle: 'Alternative Music Society', icon: Icons.cloud, color: Color(0XFFFED766)),
   AppCard(title: 'Off the Hook', subtitle: 'KnitSock', icon: Icons.cloud, color: Color(0XFFFED766)),
];

class InteractiveCard extends StatelessWidget {
  final BaseCard card;
  final VoidCallback? onTap;

  const InteractiveCard({super.key, required this.card, required this.onTap});
    
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 140,
      child:
    Material(
      color: card.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => {}, // handle tap
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(card.icon, color: Color(0XFF222222), size: 32),
              const Spacer(),
              Text(
                card.title,
                style: const TextStyle(
                  color: Color(0XFF222222),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                style: TextStyle(
                  color: Color(0XFF222222).withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: 0,
      onTap: (index) {}, // handle navigation
    );
  }
}

class MatchRow extends StatelessWidget {
  final List<MatchCard> cards;
  final String eventLabel;
  final void Function(int index) onTap;

  const MatchRow({super.key, required this.cards, required this.eventLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Text(eventLabel, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ),
      SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: cards.length,
          itemBuilder: (_, i) =>
              InteractiveCard(card: cards[i], onTap: () => onTap(i)),
        ),
      ),
    ]);
  }
}