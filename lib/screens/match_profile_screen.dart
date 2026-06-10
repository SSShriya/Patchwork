import 'package:drp/widgets/congrats_popup.dart';
import 'package:drp/widgets/user_profile_card.dart';
import 'package:flutter/material.dart';
import '../models/match_card.dart';
import '../services/match_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MatchProfileScreen extends StatefulWidget {
  final List<MatchCard> cards;
  final int initialIndex;
  final Future<void> Function(MatchCard, bool) onDecision;
  final VoidCallback onGoHome;

  const MatchProfileScreen({
    super.key,
    required this.cards,
    required this.initialIndex,
    required this.onDecision,
    required this.onGoHome,
  });

  @override
  State<MatchProfileScreen> createState() => _MatchProfileScreenState();
}

class _MatchProfileScreenState extends State<MatchProfileScreen> {
  late List<MatchCard> _cards;
  late int _index;
  bool _isAnimating = false;
  bool _goingForward = true;

  // ── Service — the only thing that talks to the DB ──
  final _matchService = MatchService();

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.cards);
    _index = widget.initialIndex;
  }

  MatchCard get _current => _cards[_index];

  void _goToPage(int newIndex, {bool goingForward = true}) {
    if (_isAnimating) return;
    _isAnimating = true;
    setState(() {
      _goingForward = goingForward;
      _index = newIndex;
    });
    Future.delayed(
      const Duration(milliseconds: 250),
      () => _isAnimating = false,
    );
  }

  void _decide(bool accepted) async {
    final card = _current;
    await widget.onDecision(card, accepted);
    if (!mounted) return;

    if (accepted) {
      // ── Delegate DB check entirely to the service ──
      final isMutual = await _matchService.hasOtherUserAccepted(card.id);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => CongratsPopup(
          match: card, 
          isMutual: isMutual,
          onGoHome: () {
              Navigator.of(dialogContext).pop();  // closes dialog 
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                // Navigator.of(context).pop(); // closes MatchProfileScreen
                widget.onGoHome();
              });
              // widget.onGoHome();
            },
          ),
      ).then((_) {
        if (!mounted) return;
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
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Swipeable profile cards ──
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -300) {
                  _goToPage(
                    _index < _cards.length - 1 ? _index + 1 : 0,
                    goingForward: true,
                  );
                } else if (velocity > 300) {
                  _goToPage(
                    _index > 0 ? _index - 1 : _cards.length - 1,
                    goingForward: false,
                  );
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (currentChild, _) =>
                    currentChild ?? const SizedBox(),
                transitionBuilder: (child, animation) {
                  final isEntering = child.key == ValueKey(_index);
                  final beginOffset = isEntering
                      ? Offset(_goingForward ? 1.0 : -1.0, 0.0)
                      : Offset(_goingForward ? -1.0 : 1.0, 0.0);
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: UserProfileCard(card: _current),
                ),
              ),
            ),
          ),

          // ── Pagination dots ──
          AnimatedSmoothIndicator(
            activeIndex: _index,
            count: _cards.length,
            effect: const WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: Color(0XFF84DCC6),
              dotColor: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          // ── Controls ──
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _goToPage(
                    _index > 0 ? _index - 1 : _cards.length - 1,
                    goingForward: false,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 4),
                      Text('Prev'),
                    ],
                  ),
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
                TextButton(
                  onPressed: () =>
                      _goToPage(_index < _cards.length - 1 ? _index + 1 : 0),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
