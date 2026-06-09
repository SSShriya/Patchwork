import 'package:drp/services/supabase_client.dart';
import 'session_manager.dart';
import 'package:intl/intl.dart';

Future<String> loadUserId() async {
  final user = supabase.auth.currentUser;
  if (user != null) return user.id;

  // Fallback to secure storage
  final id = await SessionManager.getUserId();
  if (id == null) {
    await SessionManager.clearSession();
    throw Exception("User session not found. Please log in again.");
  }
  return id;
}

String formatGroupDate(DateTime dt) {
  final now = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(dt, now)) return 'Today';
  if (sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
}

String formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String formatDate(String raw) {
  try {
    return DateFormat('EEE, MMM d yyyy').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

const String invitePrefix = 'INVITATION_DATA:';

/// Builds the raw INVITATION_DATA string from a result map.
String buildInvitePayload(Map result) =>
    '$invitePrefix{'
    '"date":"${result['date']}",'
    '"time":"${result['time']}",'
    '"location":"${result['location'] ?? ''}"'
    '}';

/// Extracts date/time/location strings from a raw invite payload.
({String date, String time, String location}) parseInvitePayload(String text) {
  final data = text.replaceFirst(invitePrefix, '');

  String pick(RegExp re) {
    final m = re.firstMatch(data);
    return m != null ? m.group(1)! : 'Not specified';
  }

  final loc = pick(RegExp(r'"location":"([^"]*)"'));
  return (
    date: pick(RegExp(r'"date":"([^"]+)"')),
    time: pick(RegExp(r'"time":"([^"]+)"')),
    location: loc.isEmpty ? 'Not specified' : loc,
  );
}

