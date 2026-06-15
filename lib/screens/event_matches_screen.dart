import 'dart:developer';

import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:drp/tools/stitched_border_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_card.dart';
import '../models/match_card.dart';
import '../services/match_service.dart';
import 'event_profile_screen.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../widgets/user_profile_card.dart';
import '../screens/society_info_screen.dart';
import '../services/event_service.dart';
import '../services/utils.dart';
import '../services/supabase_client.dart';

class EventMatchesScreen extends StatefulWidget {
  final List<EventCard> allEvents;
  final EventCard event;

  const EventMatchesScreen({
    super.key,
    required this.allEvents,
    required this.event,
  });

  @override
  State<EventMatchesScreen> createState() => _EventMatchesScreenState();
}

class _EventMatchesScreenState extends State<EventMatchesScreen> {
  final _matchService = MatchService();
  final Map<String, List<MatchCard>> _matchesByEvent = {};
  final Map<String, String> _societyNamesByEvent = {};
  final _eventService = EventService();
  final Map<String, bool> _loadingByEvent = {};

  late int _currentPage;
  bool _goingForward = true;
  bool _isAnimating = false;
  final Map<String, Map<String, dynamic>?> _committeeMemberByEvent = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.allEvents.indexWhere(
      (e) => e.eventId == widget.event.eventId,
    );
    if (_currentPage < 0) _currentPage = 0;

    for (final event in widget.allEvents) {
      _loadMatchesFor(event.eventId);
      _loadSocietyNameFor(event.eventId, event.societyId);
      if (event.meetCommittee && event.committeeMemberId != null) {
        _loadCommitteeMember(event);
      }
    }
    log("Successfully initialized page");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/textures/bg_texture.jpg'), context);
  }

  Future<void> _loadCommitteeMember(EventCard event) async {
    try {
      final data = await supabase
          .from('committee_members')
          .select('name, role, avatar_url')
          .eq('id', event.committeeMemberId!)
          .maybeSingle();
      if (mounted) {
        setState(() => _committeeMemberByEvent[event.eventId] = data);
      }
    } catch (e) {
      debugPrint('Error loading committee member: $e');
    }
  }

  Future<void> _loadMatchesFor(String eventId) async {
    if (!mounted) return;
    setState(() => _loadingByEvent[eventId] = true);
    final matches = await _matchService.getConfirmedMatchesForEvent(eventId);

    if (!mounted) return;
    setState(() {
      _matchesByEvent[eventId] = matches;
      _loadingByEvent[eventId] = false;
    });
  }

  Future<void> _loadSocietyNameFor(String eventId, String societyId) async {
    final name = await _eventService.getSocietyName(societyId);
    if (!mounted) return;
    setState(() => _societyNamesByEvent[eventId] = name);
  }

  void _goToPage(int newIndex, {bool goingForward = true}) {
    if (_isAnimating) return;
    _isAnimating = true;
    setState(() {
      _goingForward = goingForward;
      _currentPage = newIndex;
    });
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _isAnimating = false,
    );
  }

  Future<void> _initiateSocietyChat(String societyId, String eventId) async {
    final userId = await loadUserId();

    // Respect the user_order check constraint (user1_id < user2_id)
    final String user1;
    final String user2;
    if (societyId.compareTo(userId) <= 0) {
      user1 = societyId;
      user2 = userId;
    } else {
      user1 = userId;
      user2 = societyId;
    }

    try {
      await supabase.from('matches').insert({
        'user1_id': user1,
        'user2_id': user2,
        'event_id': eventId,
        'user1_accepted': true,
        'user2_accepted': true,
      });
    } catch (e) {
      // Row already exists — safe to ignore and proceed to chat
      debugPrint('Match row already exists, proceeding: $e');
    }
  }

  Widget _buildCommitteeMeetingCard(EventCard event) {
    if (!event.meetCommittee) return const SizedBox.shrink();

    final member = _committeeMemberByEvent[event.eventId];

    final avatarUrl = member?['avatar_url'] as String?;
    final name = member?['name'] as String? ?? 'Committee Member';
    final role = member?['role'] as String? ?? '';
    final location = event.committeeMeetingLocation ?? '';
    final time = event.committeeMeetingTime ?? '';

    String displayTime = time;
    final timeParts = time.split(':');
    if (timeParts.length >= 2) {
      displayTime = '${timeParts[0]}:${timeParts[1]}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            const Icon(
              Icons.handshake_outlined,
              size: 18,
              color: Color(0xFF84DCC6),
            ),
            const SizedBox(width: 8),
            const Text(
              'Committee Member Available',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'A committee member is available to meet before this event.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Color(0xFF4D5359),
          ),
        ),
        const SizedBox(height: 12),

        // ── Member card ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF84DCC6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF84DCC6).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Member info ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Avatar ──
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // ── Name & Role — takes up remaining space ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        if (role.isNotEmpty)
                          Text(
                            role,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Message button pushed to the right ──
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DMScreen(
                            chat: ChatConversation(
                              matchCard: MatchCard(
                                currentUserId: '',
                                otherUserId: event.societyId,
                                title:
                                    _societyNamesByEvent[event.eventId] ??
                                    'Society',
                                university: '',
                                course: '',
                                bio: '',
                                eventId: event.eventId,
                                eventName: event.title,
                                yearGroup: '',
                                location: '',
                                interests: [],
                                imageUrl: '',
                              ),
                              isSociety: true,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF84DCC6,
                      ).withValues(alpha: 0.4),
                      foregroundColor: const Color(0xFF222222),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(
                          color: Color(0xFF84DCC6),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Meeting details ────────────────────────────────────────
              if (location.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 16,
                      color: Color(0xFF4D5359),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          color: Color(0xFF4D5359),
                        ),
                      ),
                    ),
                  ],
                ),
              if (location.isNotEmpty) const SizedBox(height: 6),
              if (displayTime.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: Color(0xFF4D5359),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayTime,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: Color(0xFF4D5359),
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

  Widget _buildEventPage(EventCard event) {
    final matches = _matchesByEvent[event.eventId] ?? [];
    final loading = _loadingByEvent[event.eventId] ?? true;

    final built = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Event Info Card ──
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventProfileScreen(card: event),
              ),
            ),
            child: CustomPaint(
              foregroundPainter: StitchedBorderPainter(
                stitchColor: Colors.white.withValues(alpha: 0.7),
                strokeWidth: 2.6,
                dashLength: 8.0,
                gapLength: 8.0,
                borderRadius: 10.0,
                inset: 7.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          event.icon,
                          color: const Color(0xFF222222),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            event.title,
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
                    Row(
                      children: [
                        const Icon(
                          Icons.group,
                          size: 14,
                          color: Color(0xFF222222),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _societyNamesByEvent[event.eventId] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(
                              0xFF222222,
                            ).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Text(
                      event.subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF222222).withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap here to find out more!',
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0XFF224488).withValues(alpha: 0.8),
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
                          ).format(event.startDateTime),
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
                          '${DateFormat('HH:mm').format(event.startDateTime)} - ${DateFormat('HH:mm').format(event.endDateTime)}',
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
                            event.location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF222222), thickness: 0.3),
                    const SizedBox(height: 8),

                    // ── View Society Button ──────────────────────────────
                    // ── Buttons Row ────────────────────────────────────────────────
                    Row(
                      children: [
                        // Button 1: View Society
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SocietyInfoScreen(
                                societyId: event.societyId,
                                eventId: event.eventId,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF222222,
                                ).withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 16,
                                  color: Color(0xFF222222),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'View Society',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Button 2: Message Society
                        GestureDetector(
                          onTap: () async {
                            await _initiateSocietyChat(
                              event.societyId,
                              event.eventId,
                            );
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DMScreen(
                                  chat: ChatConversation(
                                    matchCard: MatchCard(
                                      currentUserId: '',
                                      otherUserId: event.societyId,
                                      title:
                                          _societyNamesByEvent[event.eventId] ??
                                          'Society',
                                      university: '',
                                      course: '',
                                      bio: '',
                                      eventId: event.eventId,
                                      eventName: event.title,
                                      yearGroup: '',
                                      location: '',
                                      interests: [],
                                      imageUrl: '',
                                    ),
                                    isSociety: true,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF222222,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF222222,
                                ).withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.message_rounded,
                                  size: 16,
                                  color: Color(0xFF222222),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Message Society',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ], // closes Column
                ),
              ),
            ),
          ),
          _buildCommitteeMeetingCard(event),

          const SizedBox(height: 24),

          // ── Matches Section ──
          Text(
            matches.isEmpty
                ? "No connections yet!"
                : "${matches.length} ${matches.length == 1 ? "Friend" : "Friends"}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 8),

          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (matches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No connections for this event yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...matches.map(
              (match) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        foregroundColor: const Color(0XFF222222),
                        flexibleSpace: Opacity(
                          opacity: 0.6,
                          child: Image(
                            image: AssetImage('assets/images/pink_gingham.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      body: UserProfileCard(card: match, accepted: true),
                    ),
                  ),
                ),
                child: Container(
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
                    // ... rest unchanged
                    children: [
                      ProfilePicture(
                        name: match.title,
                        radius: 28,
                        fontsize: 22,
                        random: false,
                        img: match.imageUrl.isNotEmpty ? match.imageUrl : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DMScreen(
                                chat: ChatConversation(matchCard: match),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0XFFEEC0C6,
                          ).withValues(alpha: 0.5),
                          foregroundColor: const Color(0xFF222222),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: Color(0XFFEEC0C6),
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return built;
  }

  @override
  Widget build(BuildContext context) {
    final currentEvent = widget.allEvents[_currentPage];

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F0F6),
      ),
      child: Stack(
        children: [
          // BACKGROUND IMG
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFFF5F0F6),
            ), // ← add solid base
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/textures/bg_texture.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0xFFF5F0F6).withValues(alpha: 0.4),
                      BlendMode.multiply,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                currentEvent.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  fontFamily: 'Lora',
                ),
              ),
              flexibleSpace: Opacity(
                opacity: 0.6,
                child: Image(
                  image: AssetImage('assets/images/yellow_gingham.png'),
                  fit: BoxFit.cover,
                ),
              ),
              foregroundColor: const Color(0XFF222222),
              elevation: 0,
            ),
            body: Column(
              children: [
                // ── AnimatedSwitcher handles circular swipe with correct direction ──
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -300) {
                        _goToPage(
                          _currentPage < widget.allEvents.length - 1
                              ? _currentPage + 1
                              : 0,
                          goingForward: true,
                        );
                      } else if (velocity > 300) {
                        _goToPage(
                          _currentPage > 0
                              ? _currentPage - 1
                              : widget.allEvents.length - 1,
                          goingForward: false,
                        );
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (currentChild, _) =>
                          currentChild ?? const SizedBox(),
                      transitionBuilder: (child, animation) {
                        final isEntering = child.key == ValueKey(_currentPage);
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
                        key: ValueKey(_currentPage),
                        child: _buildEventPage(currentEvent),
                      ),
                    ),
                  ),
                ),

                // ── Worm indicator ──
                if (widget.allEvents.length > 1) ...[
                  const SizedBox(height: 12),
                  AnimatedSmoothIndicator(
                    activeIndex: _currentPage,
                    count: widget.allEvents.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Color(0XFF84DCC6),
                      dotColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
