import 'package:drp/screens/event_cancellation_popup.dart';
import 'package:drp/screens/event_registered_popup.dart';
import 'package:drp/screens/society_info_screen.dart';
import 'package:drp/services/utils.dart';
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

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRegistered();
    _setupSocName();
  }

  Future<void> _setupSocName() async {
    try {
      final name = await eventService.getSocietyName(widget.card.societyId);
      if (mounted) {
        setState(() => societyName = name);
      }
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

    if (mounted) {
      setState(() {
        _isRegistered = isRegistered;
      });
    }
  }

  Future<void> _register() async {
    try {
      await registrationService.registerForEvent(widget.card.eventId);
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
            content: Text('Registration failed, please try again later.'),
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
      setState(() => _isRegistered = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancellation failed, please try again later'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Event image, name & datetime ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Event image placeholder
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.event, size: 36, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),

                // Event name and datetime
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

            // ── Location ──
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

            // ── Map preview (only if coordinates exist) ──
            if (widget.card.latitude != null &&
                widget.card.longitude != null) ...[
              MapPreview(
                latitude: widget.card.latitude!,
                longitude: widget.card.longitude!,
              ),
            ],

            const SizedBox(height: 10),

            // ── Cost ──
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

            SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0XFFD0F0C0),
                    foregroundColor: Color(0xFF4D5359),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
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
                      fontFamily: 'Lora',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // ── Description ──
            Text(
              'Description',
              style: const TextStyle(
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

            const SizedBox(height: 32),

            // ------ Registration Button ------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => (_isRegistered ? _unregister() : _register()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRegistered
                      ? const Color(0XFFFD5757)
                      : const Color(0XFF81D8D0),
                  foregroundColor: const Color(0XFF222222),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistered
                    ? Text(
                        "Cancel Registration",
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      )
                    : Text(
                        "I'm going!",
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
