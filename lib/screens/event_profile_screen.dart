import 'package:drp/screens/event_cancellation_popup.dart';
import 'package:drp/screens/event_registered_popup.dart';
import 'package:drp/screens/society_info_screen.dart';
import 'package:drp/services/society_service.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/utils.dart';
import 'package:drp/tools/stitched_button.dart';
import 'package:flutter/material.dart';
import '../models/event_card.dart';
import '../services/registration_service.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../widgets/map_preview.dart';

class EventProfileScreen extends StatefulWidget {
  final EventCard card;

  const EventProfileScreen({super.key, required this.card});

  @override
  State<EventProfileScreen> createState() => _EventProfileScreenState();
}

class _EventProfileScreenState extends State<EventProfileScreen> {
  RegistrationService registrationService = RegistrationService();
  bool _isRegistered = false;
  EventService eventService = EventService();
  String societyName = '';
  final SocietyService _societyService = SocietyService();

  //  committee member details ─────────────────────────────────────────
  Map<String, dynamic>? _committeeMember;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRegistered();
    _setupSocName();
    // ── NEW ──────────────────────────────────────────────────────────────────
    if (widget.card.meetCommittee && widget.card.committeeMemberId != null) {
      _loadCommitteeMember();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/textures/bg_texture.jpg'), context);
  }

  //  fetch committee member row ───────────────────────────────────────
  Future<void> _loadCommitteeMember() async {
    try {
      final data = await supabase
          .from('committee_members')
          .select('name, role, avatar_url')
          .eq('id', widget.card.committeeMemberId!)
          .maybeSingle();
      if (mounted) setState(() => _committeeMember = data);
    } catch (e) {
      debugPrint('Error loading committee member: $e');
    }
  }

  Future<void> _setupSocName() async {
    try {
      final name = await eventService.getSocietyName(widget.card.societyId);
      if (mounted) setState(() => societyName = name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t get society name: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _checkIfAlreadyRegistered() async {
    final userId = await loadUserId();
    final isRegistered = await registrationService.hasRegistered(
      widget.card.eventId,
      userId,
    );
    if (mounted) setState(() => _isRegistered = isRegistered);
  }

  Future<void> _register() async {
    try {
      await registrationService.registerForEvent(widget.card.eventId);
      final userId = await loadUserId();
      await _societyService.initiateSocietyChat(widget.card.societyId, userId, widget.card.eventId);
      setState(() => _isRegistered = true);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              EventRegisteredPopup(eventName: widget.card.title),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration failed, please try again later.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _unregister() async {
    try {
      final confirmed =
          await showDialog(
            context: context,
            builder: (context) => EventCancellationPopup(),
          ) ??
          false;
      if (!confirmed) return;
      await registrationService.unregisterForEvent(widget.card.eventId);
      if (mounted) {
        setState(() => _isRegistered = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration cancelled.'),
            backgroundColor: Color(0XFF84DCC6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cancellation failed, please try again later'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── NEW: committee meeting card widget ────────────────────────────────────
  Widget _buildCommitteeMeetingCard() {
    if (!widget.card.meetCommittee) return const SizedBox.shrink();

    final avatarUrl = _committeeMember?['avatar_url'] as String?;
    final name = _committeeMember?['name'] as String? ?? 'Committee Member';
    final role = _committeeMember?['role'] as String? ?? '';
    final location = widget.card.committeeMeetingLocation ?? '';
    final time = widget.card.committeeMeetingTime ?? '';

    // Format time — strip seconds if present e.g. "09:00:00" → "09:00"
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
                children: [
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
                  Column(
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // BACKGROUND IMG
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
            foregroundColor: const Color(0XFF222222),
            flexibleSpace: Opacity(
              opacity: 0.6,
              child: Image(
                image: AssetImage('assets/images/yellow_gingham.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Event image, name & datetime ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.event,
                        size: 36,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.card.title,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF4D5359),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('d MMM').format(widget.card.startDateTime)}  ·  '
                                '${DateFormat('HH:mm').format(widget.card.startDateTime)}'
                                '-${DateFormat('HH:mm').format(widget.card.endDateTime)}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  color: Color(0xFF4D5359),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Location ─────────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Color(0xFF4D5359),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.card.location,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: Color(0xFF4D5359),
                      ),
                    ),
                  ],
                ),

                if (widget.card.latitude != null &&
                    widget.card.longitude != null) ...[
                  MapPreview(
                    latitude: widget.card.latitude!,
                    longitude: widget.card.longitude!,
                  ),
                ],
                const SizedBox(height: 10),

                // ── Cost ─────────────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_num,
                      size: 18,
                      color: Color(0xFF4D5359),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.card.cost > 0
                          ? '£${widget.card.cost.toStringAsFixed(2)}'
                          : 'Free',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: Color(0xFF4D5359),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFFD0F0C0),
                        foregroundColor: const Color(0xFF4D5359),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SocietyInfoScreen(
                            societyId: widget.card.societyId,
                            eventId: widget.card.eventId,
                          ),
                        ),
                      ),
                      child: Text(
                        'More About $societyName',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32),

                // ── Description ──────────────────────────────────────────────
                const Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.card.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),

                // Committee meeting section ───────────────────────────
                _buildCommitteeMeetingCard(),

                const SizedBox(height: 32),

                // ── Registration button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: StitchedButton(
                    label: _isRegistered ? 'Cancel Registration' : "I'm going!",
                    backgroundColor: _isRegistered
                        ? const Color(0xFFfd5757)
                        : const Color(0xFF81D8D0),
                    foregroundColor: Colors.black87,
                    stitchColor: Colors.white,
                    onPressed: _isRegistered ? _unregister : _register,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
