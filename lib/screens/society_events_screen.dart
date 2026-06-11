import 'package:drp/services/society_events_service.dart';
import 'package:drp/widgets/create_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SocietyEventsScreen extends StatefulWidget {
  const SocietyEventsScreen({super.key});

  @override
  State<SocietyEventsScreen> createState() => _SocietyEventsScreenState();
}

class _SocietyEventsScreenState extends State<SocietyEventsScreen> {
  bool _showArchived = false;

  // ── Add new event ──────────────────────────────────────────────────────────
  Future<void> _addNewEvent(SocietySharedState state) async {
    final result = await showNewEventPopup(context);
    if (result == null) return;
    try {
      await state.createEvent(
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
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
      }
    } catch (e) {
      _snack('Failed to create event: $e');
    }
  }

  // ── Edit event ─────────────────────────────────────────────────────────────
  Future<void> _editEvent(
    SocietySharedState state,
    Map<String, String> event,
  ) async {
    final eventId = event['id'];
    if (eventId == null || eventId.isEmpty) return;

    // ── Parse start date/time ──────────────────────────────────────────────
    DateTime? parsedStartDate;
    TimeOfDay? parsedStartTime;
    DateTime? parsedEndDate;
    TimeOfDay? parsedEndTime;

    try {
      final startParts = event['start_date']!.split(' at ');
      if (startParts.length == 2) {
        parsedStartDate = DateTime.parse(startParts[0]);
        final tp = startParts[1].split(':');
        parsedStartTime = TimeOfDay(
          hour: int.parse(tp[0]),
          minute: int.parse(tp[1]),
        );
      }
      final endParts = event['end_date']!.split(' at ');
      if (endParts.length == 2) {
        parsedEndDate = DateTime.parse(endParts[0]);
        final tp = endParts[1].split(':');
        parsedEndTime = TimeOfDay(
          hour: int.parse(tp[0]),
          minute: int.parse(tp[1]),
        );
      }
    } catch (_) {
      parsedStartDate = DateTime.now();
      parsedStartTime = const TimeOfDay(hour: 9, minute: 0);
      parsedEndDate = DateTime.now().add(const Duration(hours: 2));
      parsedEndTime = const TimeOfDay(hour: 11, minute: 0);
    }

    // ── Parse committee meeting time — separate try/catch so it can never
    //    be silently wiped by the date parsing fallback above ───────────────
    TimeOfDay? existingMeetingTime;
    try {
      final rawMeetingTime = event['committee_meeting_time'] ?? '';
      if (rawMeetingTime.isNotEmpty) {
        final tp = rawMeetingTime.split(':');
        // Handle both "HH:mm" and "HH:mm:ss" formats
        if (tp.length >= 2) {
          existingMeetingTime = TimeOfDay(
            hour: int.parse(tp[0].trim()),
            minute: int.parse(tp[1].trim()),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to parse committee_meeting_time: $e');
    }

    debugPrint('meet_committee flag: ${event['meet_committee']}');
    debugPrint(
      'committee_meeting_location: ${event['committee_meeting_location']}',
    );
    debugPrint(
      'committee_meeting_time raw: ${event['committee_meeting_time']}',
    );
    debugPrint('existingMeetingTime parsed: $existingMeetingTime');

    final result = await showNewEventPopup(
      context,
      existingName: event['title'],
      existingLocation: event['location'],
      existingLatitude: double.tryParse(event['latitude'] ?? ''),
      existingLongitude: double.tryParse(event['longitude'] ?? ''),
      existingPrice: double.tryParse(event['cost'] ?? '0') ?? 0.0,
      existingStartDate: parsedStartDate,
      existingStartTime: parsedStartTime,
      existingEndDate: parsedEndDate,
      existingEndTime: parsedEndTime,
      existingDescription: event['description'],
      existingCommitteeCanMeet: event['meet_committee'] == 'true',
      existingCommitteeMeetingLocation: event['committee_meeting_location'],
      existingCommitteeMeetingTime: existingMeetingTime,
    );

    if (result == null) return;

    try {
      await state.updateEvent(
        eventId: eventId,
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
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully!')),
        );
      }
    } catch (e) {
      _snack('Failed to update event: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Event card ─────────────────────────────────────────────────────────────
  Widget _eventCard(
    SocietySharedState state,
    Map<String, String> event, {
    bool isPast = false,
  }) {
    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0x4F3E92CC),
        child: ListTile(
          onTap: isPast ? null : () => _editEvent(state, event),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPast ? Colors.grey : const Color(0xFF84DCC6))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              color: isPast ? Colors.grey : const Color(0xFF4D5359),
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
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = context.watch<SocietySharedState>();
    final active = state.events.where((e) => e['is_past'] != 'true').toList();
    final archived = state.events.where((e) => e['is_past'] == 'true').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F6),
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: const Color(0xFF84DCC6),
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF222222)),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isLoading ? null : () => _addNewEvent(state),
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
                fontFamily: 'Lora',
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
                itemBuilder: (context, index) =>
                    _eventCard(state, active[index]),
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
                      _eventCard(state, archived[index], isPast: true),
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
    );
  }
}
