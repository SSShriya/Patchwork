import 'package:flutter/material.dart';
import '../models/match_card.dart';
import '../models/app_card.dart';
import '../services/match_service.dart';
import '../widgets/interactive_card.dart';
import '../widgets/match_row.dart';
import '../widgets/app_navigation_bar.dart';
import 'user_profile_screen.dart';

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
    final groupCards = _pendingMatches
        .where((c) => c.group == card.group)
        .toList();
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

    final choirCards = _pendingMatches
        .where((c) => c.group == 'choir')
        .toList();
    final improvCards = _pendingMatches
        .where((c) => c.group == 'improv')
        .toList();

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
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Recommended Events',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              'Matches',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
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
      bottomNavigationBar: const AppNavigationBar(),
    );
  }
}
