import 'package:flutter/material.dart';
import '../models/dm_message.dart';
import '../services/utils.dart';

const _primaryColor = Color(0xFF8789C0);
const _accentDark = Color(0xFF409A83);

class DmPinnedBanner extends StatelessWidget {
  final List<DmMessage> messages;
  final void Function(int index) onTap;

  const DmPinnedBanner({
    super.key,
    required this.messages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final index = messages.lastIndexWhere(
      (m) => m.isInvitation && m.invitationStatus != false,
    );
    if (index == -1) return const SizedBox.shrink();

    final msg = messages[index];
    final parsed = parseInvitePayload(msg.text);

    final (statusText, statusColor) = switch (msg.invitationStatus) {
      true => ('Accepted ✓', _accentDark),
      false => ('Declined ✕', Colors.red),
      _ => ('Pending', Colors.orange),
    };

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, size: 16, color: _primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pinned Meeting',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📅 ${formatDate(parsed.date)}  ⏰ ${parsed.time}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
