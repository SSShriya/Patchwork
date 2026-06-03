import 'package:drp/screens/event_registered_popup.dart';
import 'package:flutter/material.dart';
import '../models/event_card.dart';
import '../services/registration_service.dart';
import '../widgets/app_navigation_bar.dart';
import 'package:intl/intl.dart';

class EventProfileScreen extends StatefulWidget {
  final EventCard card;

  const EventProfileScreen({super.key, required this.card});

  @override
  State<EventProfileScreen> createState() => _EventProfileScreenState();
}

class _EventProfileScreenState extends State<EventProfileScreen> {
  RegistrationService registrationService = RegistrationService();
  bool _isRegistered = false; 

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRegistered(); 
  }

  Future<void> _checkIfAlreadyRegistered() async {
    final isRegistered = await registrationService.hasRegistered(
      widget.card.eventId,
    );

    if (mounted) {
      setState(() {
        _isRegistered = isRegistered;
      });
    }
  }

  Future<void> _register() async {
    registrationService.registerForEvent(widget.card.eventId);

    showDialog(
      context: context,
      builder: (context) => EventRegisteredPopup(eventName: widget.card.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 1), 
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
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: Colors.grey[600],
                  ),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('d MMM').format(widget.card.startDateTime)}  ·  '
                            '${DateFormat('HH:mm').format(widget.card.startDateTime)}'
                            '-${DateFormat('HH:mm').format(widget.card.endDateTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
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
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  widget.card.location,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Cost ──
            Row(
              children: [
                const Icon(Icons.confirmation_num, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  widget.card.cost > 0 ? '£${widget.card.cost.toStringAsFixed(2)}' : 'Free',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),

            const Divider(height: 32),

            // ── Description ──
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.card.subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // ------ Registration Button ------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRegistered ? null : () => _register(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0XFF84DCC6),
                  foregroundColor: const Color(0XFF222222),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistered ? const Text(
                    "You're already registered!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ) : const Text(
                    "I'm going!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 32),
          ]
        )
      )
    );
  }
}