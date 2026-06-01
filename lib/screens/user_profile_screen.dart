import 'package:drp/screens/congrats_popup.dart';
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
  bool _isAnimating = false;
  bool _goingForward = true;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.cards);
    _index = widget.initialIndex;
  }

  @override
  void dispose() {
    super.dispose();
  }

  MatchCard get _current => _cards[_index];

  void _goToPage(int newIndex) {
    if (_isAnimating) return;
    _isAnimating = true;
    setState(() {
      _goingForward = newIndex > _index;
      _index = newIndex;
    });
    Future.delayed(const Duration(milliseconds: 250), () => _isAnimating = false);
  }

void _decide(bool accepted) {
  final card = _current;
  widget.onDecision(card, accepted);

  if (accepted) {
    showDialog(
      context: context,
      builder: (context) => CongratsPopup(matchName: card.title),
    ).then((_) {
      setState(() {
        _cards.remove(card);
        if (_cards.isEmpty) {
          Navigator.pop(context);
          return;
        }
        if (_index >= _cards.length) _index = _cards.length - 1;
      });
    });
  } else {
    setState(() {
      _cards.remove(card);
      if (_cards.isEmpty) {
        Navigator.pop(context);
        return;
      }
      if (_index >= _cards.length) _index = _cards.length - 1;
    });
  }
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
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -300 && _index < _cards.length - 1) {
                  _goToPage(_index + 1);
                } else if (velocity > 300 && _index > 0) {
                  _goToPage(_index - 1);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: ((currentChild, previousChildren) {
                  return currentChild ?? const SizedBox();
                }),
                transitionBuilder: (child, animation) {
                  final isEntering = child.key == ValueKey(_index);
                  final beginOffset = isEntering
                      ? Offset(_goingForward ? 1.0 : -1.0, 0.0)
                      : Offset(_goingForward ? -1.0 : 1.0, 0.0);
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0XFF8789C0),
                              child: Text(
                                _current.title[0],
                                style: const TextStyle(fontSize: 32, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(                              // fixes layout overflow on long names
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _current.title,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_current.yearGroup} at ${_current.subtitle}',
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // -- shared event group --
                        Text(
                          'You both want to attend:',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _current.group.toUpperCase(),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF5DA9E9), fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 24),

                        // -- interests --
                        const Text(
                          'Interests:', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 3),
                        ..._current.interests.map(
                          (interest) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('★ ', style: TextStyle(fontSize: 16)),
                                Expanded(
                                  child: Text(interest, style: const TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // -- Bio --
                        const Text(
                          'Bio:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_current.bio, style: const TextStyle(fontSize: 16)),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _index > 0 ? () => _goToPage(_index - 1) : null,
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
                      ? () => _goToPage(_index + 1)
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
