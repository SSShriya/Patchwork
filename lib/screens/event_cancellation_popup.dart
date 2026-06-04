import 'package:flutter/material.dart';

class EventCancellationPopup extends StatelessWidget {

  const EventCancellationPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Registration'),
      content: const Text('Are you sure you want to cancel your registration for this event?'),
      actions: [
        // ── "No" button ──
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'No',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        // ── "Yes" button ──
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Yes',
            style: TextStyle(color: Color(0XFFFD5757)),
          ),
        ),
      ],
    );
  }
}