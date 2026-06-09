import 'package:drp/models/match_card.dart';
import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:drp/services/utils.dart';
import 'package:flutter/material.dart';

class CongratsPopup extends StatefulWidget {
  final MatchCard match;
  final bool isMutual;
  final VoidCallback onGoHome;

  const CongratsPopup({
    super.key, 
    required this.match, 
    required this.isMutual,
    required this.onGoHome,
  });

  @override
  State<CongratsPopup> createState() => _CongratsPopupState();
}

class _CongratsPopupState extends State<CongratsPopup> {
  late final Future<String> _currentUserIdFuture;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = loadUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CONGRATS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0XFF8789C0),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You've accepted",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.match.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ── DM or waiting message ──
            if (widget.isMutual)
              FutureBuilder<String>(
                future: _currentUserIdFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0XFF8789C0)),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      'Unable to load user data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final currentUserId = snapshot.data!;
                  return _button(
                    label: 'DM Now',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          final parts = widget.match.id.split('|');
                          final otherUserId = parts[0] == currentUserId
                              ? parts[1]
                              : parts[0];

                          final dmCard = MatchCard(
                            id: otherUserId,
                            title: widget.match.title,
                            university: widget.match.university,
                            course: widget.match.course,
                            bio: widget.match.bio,
                            eventId: widget.match.eventId,
                            eventName: widget.match.eventName,
                            yearGroup: widget.match.yearGroup,
                            interests: widget.match.interests,
                            location: widget.match.location,
                            imageUrl: widget.match.imageUrl,
                          );

                          return DMScreen(
                            chat: ChatConversation(matchCard: dmCard),
                          );
                        },
                      ),
                    ),
                  );
                },
              )
            else
              Column(
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    color: Color(0XFF8789C0),
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Waiting for ${widget.match.title} to accept...\nYou'll be able to DM once they do!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            _button(
              label: 'Next Match',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _button(
              label: 'Back to Home',
              onPressed: () {
                Navigator.pop(context);
                onGoHome();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({required String label, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0XFF8789C0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
