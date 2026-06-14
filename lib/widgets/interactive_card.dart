import 'package:drp/models/event_card.dart';
import 'package:drp/tools/zig_zag_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../models/base_card.dart';
import '../models/match_card.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';

class InteractiveCard extends StatefulWidget {
  final BaseCard card;
  final VoidCallback? onTap;

  const InteractiveCard({super.key, required this.card, required this.onTap});

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  final EventService _eventService = EventService();
  String _societyName = '';

  @override
  void initState() {
    super.initState();
    if (widget.card is EventCard) {
      final eventCard = widget.card as EventCard;
      if (eventCard.societyId.isNotEmpty) {
        _fetchSocietyName(eventCard.societyId);
      }
    }
  }

  Future<void> _fetchSocietyName(String societyId) async {
    try {
      final name = await _eventService.getSocietyName(societyId);
      if (mounted) {
        setState(() {
          _societyName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _societyName = ''; // fallback on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchCard = widget.card is MatchCard
        ? widget.card as MatchCard
        : null;
    final eventCard = widget.card is EventCard
        ? widget.card as EventCard
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 186,
      child: ClipPath(
        clipper: ZigZagClipper(toothSize: 8),
        child: Material(
          color: widget.card.color,
          child: InkWell(
            onTap: widget.onTap ?? () => {},
            child: Stack(
              children: [
                // FABRIC TEXTURE
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.17,
                    child: Image.asset(
                      'assets/textures/linen.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // CONTENT
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // ── Top Row: Icon + Matches Badge ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.card.imageUrl.isNotEmpty)
                            ProfilePicture(
                              name: widget.card.title,
                              radius: 12,
                              fontsize: 32,
                              random: false,
                              img: widget.card.imageUrl.isNotEmpty
                                  ? widget.card.imageUrl
                                  : null,
                            )
                          else
                            Icon(
                              widget.card.icon,
                              color: const Color(0xFF222222),
                              size: 28,
                            ),
                          const Spacer(),
                          if (eventCard != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: eventCard.numMatches == 0
                                    ? const Color(
                                        0xFF220000,
                                      ).withValues(alpha: 0.2)
                                    : const Color(
                                        0xFF84DCC6,
                                      ).withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                eventCard.numMatches == 0
                                    ? 'No one yet!'
                                    : '${eventCard.numMatches} ${eventCard.numMatches == 1 ? 'friend' : 'friends'}',
                                style: const TextStyle(
                                  color: Color(0xFF222222),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // ── Title ──
                      Text(
                        widget.card.title,
                        style: const TextStyle(
                          fontFamily: 'Bitter',
                          color: Color(0xFF222222),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Year group for match card
                      if (matchCard != null && !matchCard.isCommitteeCard) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              size: 10,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            if (matchCard.yearGroup != '')
                              Expanded(
                                child: Text(
                                  matchCard.yearGroup,
                                  style: TextStyle(
                                    fontFamily: 'Merriweather',
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF222222,
                                    ).withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],

                      // University
                      if (matchCard != null && !matchCard.isCommitteeCard) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 10,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            if (matchCard.university != '')
                              Expanded(
                                child: Text(
                                  matchCard.university,
                                  style: TextStyle(
                                    fontFamily: 'Merriweather',
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF222222,
                                    ).withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Location for match card
                      if (matchCard != null &&
                          matchCard.location.isNotEmpty &&
                          !matchCard.isCommitteeCard) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                matchCard.location,
                                style: TextStyle(
                                  fontFamily: 'Merriweather',
                                  color: const Color(
                                    0xFF222222,
                                  ).withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Interests
                      if (matchCard != null &&
                          matchCard.interests.isNotEmpty &&
                          !matchCard.isCommitteeCard) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Interests:',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            color: Color(0xFF222222),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: matchCard.interests
                              .take(3)
                              .map(
                                (interest) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '★ ',
                                        style: TextStyle(
                                          fontFamily: 'Merriweather',
                                          color: Color(0xFF222222),
                                          fontSize: 13,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          interest,
                                          style: const TextStyle(
                                            fontFamily: 'Merriweather',
                                            color: Color(0xFF222222),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      // Committee Card
                      if (matchCard != null && matchCard.isCommitteeCard) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Committee Member',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            color: Color(0xFF222222),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group,
                              size: 12,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                matchCard.societyName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Merriweather',
                                  color: Color(0xFF222222),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge,
                              size: 12,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                matchCard.course,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Merriweather',
                                  color: Color(0xFF222222),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Society Name (EventCard only) ──
                      if (eventCard != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.group,
                              size: 12,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: _societyName.isEmpty
                                  ? const SizedBox(
                                      // 👈 show nothing while loading
                                      height: 12,
                                      width: 60,
                                    )
                                  : Text(
                                      _societyName, // 👈 use state variable
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Merriweather',
                                        color: Color(0xFF222222),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                      ],

                      // ── Date & Time & Location (EventCard only) ──
                      if (eventCard != null) ...[
                        const Spacer(),
                        const Divider(
                          color: Color(0xFF222222),
                          thickness: 0.3,
                          height: 8,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('d MMM').format(eventCard.startDateTime)}  ·  '
                          '${DateFormat('HH:mm').format(eventCard.startDateTime)}-'
                          '${DateFormat('HH:mm').format(eventCard.endDateTime)}',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            color: const Color(
                              0xFF222222,
                            ).withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 11,
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                eventCard.location,
                                style: TextStyle(
                                  fontFamily: 'Merriweather',
                                  color: const Color(
                                    0xFF222222,
                                  ).withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
