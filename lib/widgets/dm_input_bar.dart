import 'package:flutter/material.dart';

const _accentColor = Color(0xFF84DCC6);

class DmInputBar extends StatelessWidget {
  final TextEditingController controller;
  final String recipientName;
  final VoidCallback onSend;

  const DmInputBar({
    super.key,
    required this.controller,
    required this.recipientName,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Message $recipientName...',
                  hintStyle: const TextStyle(fontFamily: 'Montserrat'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _accentColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
