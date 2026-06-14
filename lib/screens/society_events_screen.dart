import 'package:drp/tools/scalloped_clipper.dart';
import 'package:drp/tools/stitched_border_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/society_service.dart';
import 'package:drp/services/utils.dart';
import 'package:drp/widgets/create_event.dart';

class SocietyEventsScreen extends StatefulWidget {
  const SocietyEventsScreen({super.key});

  @override
  State<SocietyEventsScreen> createState() => _SocietyEventsScreenState();
}

class _SocietyEventsScreenState extends State<SocietyEventsScreen> {
  String _societyId = '';
  List<Map<String, String>> _events = [];
  bool _isLoading = false;
  bool _showArchived = false;

  final SocietyService _societyService = SocietyService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/textures/bg_texture.jpg'), context);
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      _societyId = await loadUserId();
      if (_societyId.isEmpty) return;

      final eventsData = await _societyService.getSocietyEvents(_societyId);
      if (!mounted) return;

      final today = DateTime.now();
      final parsed = <Map<String, String>>[];

      for (final e in eventsData) {
        final endDay = DateTime.tryParse(e['end_day'] ?? '');
        final isPast = endDay != null && endDay.isBefore(today);
        final startDayStr = e['start_day'] ?? '';
        final endDayStr = e['end_day'] ?? '';
        final startTimeStr = e['start_time'] ?? '';
        final endTimeStr = e['end_time'] ?? '';

        // ── Human-readable display strings ──────────────────────────────────
        String startDisplay = startDayStr;
        String endDisplay = endDayStr;
        try {
          startDisplay =
              '${DateFormat('EEE d MMM yyyy').format(DateTime.parse(startDayStr))}'
              ' at '
              '${DateFormat('HH:mm').format(DateTime.parse('1970-01-01T$startTimeStr'))}';
          endDisplay =
              '${DateFormat('EEE d MMM yyyy').format(DateTime.parse(endDayStr))}'
              ' at '
              '${DateFormat('HH:mm').format(DateTime.parse('1970-01-01T$endTimeStr'))}';
        } catch (_) {}

        parsed.add({
          'id': '${e['event_id']}',
          'title': e['event_name'] ?? '',
          'start_date': startDisplay,
          'end_date': endDisplay,
          'start_day_raw': startDayStr,
          'start_time_raw': startTimeStr,
          'end_day_raw': endDayStr,
          'end_time_raw': endTimeStr,
          'location': e['location'] ?? '',
          'cost': '${e['cost']}',
          'description': e['description'] ?? '',
          'latitude': e['latitude'] != null ? '${e['latitude']}' : '',
          'longitude': e['longitude'] != null ? '${e['longitude']}' : '',
          'is_past': isPast ? 'true' : 'false',
          'meet_committee': '${e['meet_committee'] ?? false}',
          'committee_meeting_location': e['committee_meeting_location'] ?? '',
          'committee_meeting_time': e['committee_meeting_time'] ?? '',
          'committee_member_id': e['committee_member_id'] ?? '',
          'image_url': e['image_url'] ?? '',
        });
      }

      parsed.sort((a, b) {
        final aDate = DateTime.tryParse(a['start_day_raw']!) ?? DateTime.now();
        final bDate = DateTime.tryParse(b['start_day_raw']!) ?? DateTime.now();
        final aIsPast = a['is_past'] == 'true';
        final bIsPast = b['is_past'] == 'true';
        if (aIsPast != bIsPast) return aIsPast ? 1 : -1;
        return aIsPast ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
      });

      setState(() => _events = parsed);
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Add new event ──────────────────────────────────────────────────────────
  Future<void> _addNewEvent() async {
    final result = await showNewEventPopup(context, societyId: _societyId);
    if (result == null) return;
    setState(() => _isLoading = true);
    try {
      final newEventId = await _societyService.createSocietyEvent(
        societyId: _societyId,
        name: result.name,
        startDate: result.startDate,
        startTime: result.startTime,
        endDate: result.endDate,
        endTime: result.endTime,
        location: result.location,
        price: result.price,
        image: result.image,
        description: result.description,
        latitude: result.latitude,
        longitude: result.longitude,
        committeeCanMeet: result.committeeCanMeet,
        committeeMeetingLocation: result.committeeMeetingLocation,
        committeeMeetingTime: result.committeeMeetingTime,
        committeeMemberId: result.committeeMemberId,
      );
      await supabase.from('interested_events').insert({
        'user_id': _societyId,
        'event_id': newEventId,
      });
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
      }
    } catch (e) {
      _snack('Failed to create event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Edit event ─────────────────────────────────────────────────────────────
  Future<void> _editEvent(Map<String, String> event) async {
    final eventId = event['id'];
    if (eventId == null || eventId.isEmpty) return;

    // ── Build full DateTimes from the raw ISO strings stored in the map ──────
    // e.g. start_day_raw = "2026-06-03", start_time_raw = "18:00:00"
    // Combine them into "2026-06-03T18:00:00" and parse once.
    // splitDateTime() (from create_event.dart) then separates the date part
    // from the TimeOfDay part — no fragile display-string parsing needed.
    DateTime? existingStartDateTime;
    DateTime? existingEndDateTime;

    final startDayRaw = event['start_day_raw'] ?? '';
    final startTimeRaw = event['start_time_raw'] ?? '';
    final endDayRaw = event['end_day_raw'] ?? '';
    final endTimeRaw = event['end_time_raw'] ?? '';

    if (startDayRaw.isNotEmpty) {
      final timeStr = startTimeRaw.isNotEmpty ? startTimeRaw : '00:00:00';
      existingStartDateTime = DateTime.tryParse(
        '${startDayRaw}T${timeStr.substring(0, 8)}',
      );
    }
    if (endDayRaw.isNotEmpty) {
      final timeStr = endTimeRaw.isNotEmpty ? endTimeRaw : '00:00:00';
      existingEndDateTime = DateTime.tryParse(
        '${endDayRaw}T${timeStr.substring(0, 8)}',
      );
    }

    // ── Parse committee meeting time from "HH:mm:ss" ─────────────────────────
    // parseTimeOfDay() is the helper exported from create_event.dart
    final existingMeetingTime = parseTimeOfDay(event['committee_meeting_time']);

    final result = await showNewEventPopup(
      context,
      existingName: event['title'],
      existingStartDateTime: existingStartDateTime,
      existingEndDateTime: existingEndDateTime,
      existingLocation: event['location'],
      existingLatitude: double.tryParse(event['latitude'] ?? ''),
      existingLongitude: double.tryParse(event['longitude'] ?? ''),
      existingPrice: double.tryParse(event['cost'] ?? '0') ?? 0.0,
      existingDescription: event['description'],
      existingCommitteeCanMeet: event['meet_committee'] == 'true',
      existingCommitteeMeetingLocation: event['committee_meeting_location'],
      existingCommitteeMeetingTime: existingMeetingTime,
      existingCommitteeMemberId: event['committee_member_id'],
      societyId: _societyId,
      existingImageUrl: event['image_url'],
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      await _societyService.updateSocietyEvent(
        eventId: eventId,
        societyId: _societyId,
        name: result.name,
        startDate: result.startDate,
        startTime: result.startTime,
        endDate: result.endDate,
        endTime: result.endTime,
        location: result.location,
        price: result.price,
        image: result.image,
        existingImageUrl: result.existingImageUrl,
        description: result.description,
        latitude: result.latitude,
        longitude: result.longitude,
        committeeCanMeet: result.committeeCanMeet,
        committeeMeetingLocation: result.committeeMeetingLocation,
        committeeMeetingTime: result.committeeMeetingTime,
        committeeMemberId: result.committeeMemberId,
      );
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully!')),
        );
      }
    } catch (e) {
      _snack('Failed to update event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Event card ─────────────────────────────────────────────────────────────
  Widget _eventCard(Map<String, String> event, {bool isPast = false}) {
    final imageUrl = event['image_url'] ?? '';

    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomPaint(
          foregroundPainter: StitchedBorderPainter(
            stitchColor: Colors.white.withValues(alpha: 0.8),
            strokeWidth: 2.6,
            dashLength: 8.0,
            gapLength: 8.0,
            borderRadius: 12.0,
            inset: 6.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x4F3E92CC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: isPast ? null : () => _editEvent(event),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    // Show event photo if image_url exists
                    ? Image.network(
                        imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        // ── Show icon while loading ──────────────────────────
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  (isPast
                                          ? Colors.grey
                                          : const Color(0xFF84DCC6))
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        // ── Fallback icon if image fails to load ─────────────
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                                (isPast ? Colors.grey : const Color(0xFF84DCC6))
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: isPast
                                ? Colors.grey
                                : const Color(0xFF4D5359),
                          ),
                        ),
                      )
                    // Fallback icon if no image_url
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              (isPast ? Colors.grey : const Color(0xFF84DCC6))
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: isPast ? Colors.grey : const Color(0xFF4D5359),
                        ),
                      ),
              ),
              title: Text(
                event['title']!,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isPast ? Colors.grey : Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${event['start_date']} • ${event['location']}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Color(0xFF4D5359),
                  ),
                ),
              ),
              trailing: isPast
                  ? null
                  : const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final active = _events.where((e) => e['is_past'] != 'true').toList();
    final archived = _events.where((e) => e['is_past'] == 'true').toList();

    return Stack(
      children: [
        // BACKGROUND IMAGE
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 10),
            child: ClipPath(
              clipper: ScallopedClipper(),
              child: AppBar(
                title: const Text(
                  'Events',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    fontFamily: 'Lora',
                  ),
                ),
                foregroundColor: const Color(0xFF222222),
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: Opacity(
                  opacity: 0.6,
                  child: Image(
                    image: AssetImage('assets/images/teal_gingham.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                centerTitle: true,
                actions: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: _isLoading ? null : _addNewEvent,
            backgroundColor: const Color(0xFF84DCC6),
            foregroundColor: const Color(0xFF222222),
            icon: const Icon(Icons.add),
            label: const Text(
              'New Event',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPCOMING EVENTS',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 12),

                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No upcoming events. Tap + New Event to add one.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: active.length,
                    itemBuilder: (context, index) => _eventCard(active[index]),
                  ),

                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _showArchived = !_showArchived),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Past events (${archived.length})',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4D5359),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: _showArchived ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: archived.length,
                      itemBuilder: (context, index) =>
                          _eventCard(archived[index], isPast: true),
                    ),
                    crossFadeState: _showArchived
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
