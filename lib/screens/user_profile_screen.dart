import 'package:flutter/material.dart';
import '../models/match_card.dart';

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
    widget.onDecision(
      card,
      accepted,
    ); // → saves to Supabase, removes from HomeScreen
    setState(() {
      _cards.remove(card);
      if (_cards.isEmpty) {
        Navigator.pop(context);
        return;
      }
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0XFF8789C0),
                        child: Text(
                          _current.title[0],
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _current.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_current.course} at ${_current.subtitle}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _current.bio,
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Interested in:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _current.event,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),

                  const SizedBox(height: 80), // space for buttons
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  ),
                  onPressed: () => _decide(false),
                  child: const Text('✕'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
