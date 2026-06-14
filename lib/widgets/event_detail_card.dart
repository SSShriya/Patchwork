import 'package:drp/tools/zig_zag_clipper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_card.dart';
import '../services/event_service.dart';

class EventDetailCard extends StatefulWidget {
  final EventCard card;
  final VoidCallback? onTap;
  final bool isListView;

  const EventDetailCard({
    super.key,
    required this.card,
    required this.onTap,
    this.isListView = false,
  });

  @override
  State<EventDetailCard> createState() => _EventDetailCardState();
}

class _EventDetailCardState extends State<EventDetailCard> {
  final _eventService = EventService();
  String _societyName = '';

  @override
  void initState() {
    super.initState();
    if (widget.card.societyId.isNotEmpty) {
      _fetchSocietyName(widget.card.societyId);
    }
  }

  Future<void> _fetchSocietyName(String societyId) async {
    try {
      final name = await _eventService.getSocietyName(societyId);
      if (mounted) {
        setState(() => _societyName = name);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _societyName = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ZigZagClipper(toothSize: 6.8),
      child: Material(
        color: widget.card.color,
        child: InkWell(
          onTap: widget.onTap ?? () {},
          child: Stack(
            children: [
              // LINEN TEXTURE
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
                padding: const EdgeInsets.all(14),
                child: widget.isListView
                    ? _buildListLayout()
                    : _buildGridLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Circle image ──
        if (widget.card.imageUrl.isNotEmpty)
          CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(widget.card.imageUrl),
            onBackgroundImageError: (_, _) {},
            backgroundColor: const Color(0xFF222222).withValues(alpha: 0.1),
          )
        else
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF222222).withValues(alpha: 0.1),
            child: Icon(
              Icons.event,
              color: const Color(0xFF222222).withValues(alpha: 0.5),
            ),
          ),

        const SizedBox(width: 12),

        // ── Text content ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Title ──
              Text(
                widget.card.title,
                style: const TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Society Name ──
              if (_societyName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: 12,
                      color: const Color(0xFF222222).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _societyName,
                        style: TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 12,
                          color: const Color(0xFF222222).withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              if (widget.card.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.card.subtitle,
                  style: TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 12,
                    color: const Color(0xFF222222).withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: const Color(0xFF222222).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${DateFormat('d MMM').format(widget.card.startDateTime)}  ·  '
                    '${DateFormat('HH:mm').format(widget.card.startDateTime)}'
                    '-${DateFormat('HH:mm').format(widget.card.endDateTime)}',
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 11,
                      color: Color(0xFF222222).withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: const Color(0xFF222222).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      widget.card.location,
                      style: TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 11,
                        color: Color(0xFF222222).withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.sell,
                    size: 12,
                    color: const Color(0xFF222222).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    widget.card.cost == 0
                        ? 'Free'
                        : '£${widget.card.cost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 11,
                      color: const Color(0xFF222222).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // ── Image header ──
        if (widget.card.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              widget.card.imageUrl,
              height: 75,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

        if (widget.card.imageUrl.isNotEmpty) const SizedBox(height: 8),

        // ── Title ──
        Row(
          children: [
            Expanded(
              child: Text(
                widget.card.title,
                style: const TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // ── Society Name ──
        if (_societyName.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.group,
                size: 12,
                color: const Color(0xFF222222).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _societyName,
                  style: TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 12,
                    color: const Color(0xFF222222).withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 3),

        // ── Subtitle ──
        if (widget.card.subtitle.isNotEmpty)
          Expanded(
            child: Text(
              widget.card.subtitle,
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 12,
                color: const Color(0xFF222222).withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.clip,
            ),
          )
        else
          const Spacer(),

        const SizedBox(height: 6),
        const Divider(color: Color(0xFF222222), thickness: 0.3, height: 4),
        const SizedBox(height: 5),

        // ── Date & Time ──
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: const Color(0xFF222222).withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${DateFormat('d MMM').format(widget.card.startDateTime)}  ·  '
                '${DateFormat('HH:mm').format(widget.card.startDateTime)}'
                '-${DateFormat('HH:mm').format(widget.card.endDateTime)}',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 12,
                  color: const Color(0xFF222222).withValues(alpha: 0.8),
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
              size: 14,
              color: const Color(0xFF222222).withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.card.location,
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 12,
                  color: const Color(0xFF222222).withValues(alpha: 0.8),
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
              size: 14,
              color: const Color(0xFF222222).withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              widget.card.cost == 0
                  ? 'Free'
                  : '£${widget.card.cost.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 12,
                color: const Color(0xFF222222).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
