import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_card.dart';
import '../models/match_card.dart';
import '../services/match_service.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class EventMatchesScreen extends StatefulWidget {
  final EventCard event;

  const EventMatchesScreen({super.key, required this.event});

  @override
  State<EventMatchesScreen> createState() => _EventMatchesScreenState();
}

class _EventMatchesScreenState extends State<EventMatchesScreen> {
  final _matchService = MatchService();
  List<MatchCard> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final matches = await _matchService.getConfirmedMatchesForEvent(
      widget.event.eventId,
    );
    setState(() {
      _matches = matches;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFF5F0F6),
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: widget.event.color,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Event Info Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.event.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.event.icon,
                      color: const Color(0xFF222222),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFF222222).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF222222), thickness: 0.3),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF222222),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                      ).format(widget.event.startDateTime),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF222222),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('HH:mm').format(widget.event.startDateTime)} - ${DateFormat('HH:mm').format(widget.event.endDateTime)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFF222222),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.event.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Matches Section ──
          Text(
            '${_matches.length} ${_matches.length == 1 ? 'Match' : 'Matches'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_matches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No confirmed matches for this event yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // ── Match Cards ──
            ..._matches.map(
              (match) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Avatar ──
                    // Replace CircleAvatar with:
                    ProfilePicture(
                      name: match.title,
                      radius: 28,
                      fontsize: 22,
                      random: false,
                      img: match.imageUrl.isNotEmpty ? match.imageUrl : null,
                    ),
                    const SizedBox(width: 12),
                    // ── Details ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Name ──
                          Text(
                            match.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // ── Year · University · Course ──
                          if (match.yearGroup.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 13,
                                  color: const Color(
                                    0xFF222222,
                                  ).withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${match.yearGroup} · ${match.university} · ${match.course}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(
                                        0xFF222222,
                                      ).withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ── Location ──
                          if (match.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 13,
                                  color: const Color(
                                    0xFF222222,
                                  ).withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    match.location,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(
                                        0xFF222222,
                                      ).withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ── Interests ──
                          if (match.interests.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: match.interests
                                  .take(3)
                                  .map(
                                    (interest) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0XFFEEC0C6,
                                        ).withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        interest,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
