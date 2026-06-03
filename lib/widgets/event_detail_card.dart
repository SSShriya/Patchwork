import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/event_card.dart';

class EventDetailCard extends StatelessWidget {
  final EventCard card;
  final VoidCallback? onTap;

  const EventDetailCard({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: card.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image or colour header ──
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: card.imageUrl.isNotEmpty
                    ? Image.network(
                        card.imageUrl,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _colorHeader(),
                      )
                    : _colorHeader(),
              ),

              // ── Content ──
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──
                    Text(
                      card.title,
                      style: GoogleFonts.bitter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF222222),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // ── Subtitle ──
                    if (card.subtitle.isNotEmpty)
                      Text(
                        card.subtitle,
                        style: GoogleFonts.merriweather(
                          fontSize: 10,
                          color: const Color(0xFF222222).withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 6),
                    const Divider(
                      color: Color(0xFF222222),
                      thickness: 0.3,
                      height: 4,
                    ),
                    const SizedBox(height: 5),

                    // ── Date & Time ──
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: const Color(0xFF222222).withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${DateFormat('d MMM').format(card.startDateTime)}  ·  '
                            '${DateFormat('HH:mm').format(card.startDateTime)}'
                            '-${DateFormat('HH:mm').format(card.endDateTime)}',
                            style: GoogleFonts.merriweather(
                              fontSize: 10,
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
                    const SizedBox(height: 3),

                    // ── Location ──
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 10,
                          color: const Color(0xFF222222).withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            card.location,
                            style: GoogleFonts.merriweather(
                              fontSize: 10,
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
                    const SizedBox(height: 3),

                    // ── Cost ──
                    Row(
                      children: [
                        Icon(
                          Icons.sell,
                          size: 10,
                          color: const Color(0xFF222222).withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          card.cost == 0
                              ? 'Free'
                              : '£${card.cost.toStringAsFixed(2)}',
                          style: GoogleFonts.merriweather(
                            fontSize: 10,
                            color: const Color(
                              0xFF222222,
                            ).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorHeader() {
    return Container(
      height: 80,
      width: double.infinity,
      color: card.color.withValues(alpha: 0.6),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(card.icon, size: 24, color: const Color(0xFF222222)),
        ),
      ),
    );
  }
}
