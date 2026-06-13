import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/event_service.dart';
import 'package:image_picker/image_picker.dart';

// ── Profile queries ───────────────────────────────────────────────────────────

Future<Map<String, dynamic>?> getSocDetails(String societyId) async {
  final row = await supabase
      .from('users')
      .select('id, name, university, bio, location, avatar_url, can_message')
      .eq('id', societyId)
      .eq('is_society', true)
      .maybeSingle();

  if (row == null) return null;

  return {
    'id': row['id'],
    'name': row['name'],
    'uni': row['university'],
    'bio': row['bio'],
    'location': row['location'],
    'image_url': row['avatar_url'],
    'can_message': row['can_message'],
  };
}

Future<void> updateSocDetails({
  required String id,
  String? bio,
  String? uni,
}) async {
  final updates = <String, dynamic>{};
  if (bio != null) updates['bio'] = bio;
  if (uni != null) updates['university'] = uni;

  if (updates.isEmpty) return; // nothing to update

  await supabase.from('users').update(updates).eq('id', id);
}

Future<void> uploadSocImage(XFile imageFile, String socId) async {
  final filePath = '$socId/profile.jpg';
  try {
    final bytes = await imageFile.readAsBytes();

    await supabase.storage
        .from('avatars')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

    await supabase
        .from('users')
        .update({'avatar_url': publicUrl})
        .eq('id', socId);
  } on StorageException catch (e) {
    throw Exception('Failed to upload profile picture: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error during profile picture upload: $e');
  }
}

// ── Committee queries ─────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getCommittee(String societyId) async {
  try {
    return await supabase
        .from('committee_members')
        .select()
        .eq('society_id', societyId);
  } catch (e) {
    debugPrint('Error fetching committee data: $e');
    return [];
  }
}

Future<void> addCommitteeMember({
  required String societyId,
  required String name,
  required String role,
}) async {
  await supabase.from('committee_members').insert({
    'name': name,
    'role': role,
    'society_id': societyId,
  });
}

Future<void> removeCommitteeMember(dynamic id) async {
  await supabase.from('committee_members').delete().eq('id', id);
}

// ── Event queries ─────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getSocietyEvents(String societyId) async {
  return await supabase.from('events').select().eq('society_id', societyId);
}

Future<String> createSocietyEvent({
  required String societyId,
  required String name,
  required DateTime startDate,
  required TimeOfDay startTime,
  required DateTime endDate,
  required TimeOfDay endTime,
  required String location,
  required double price,
  XFile? image,
  String? description,
  double? latitude,
  double? longitude,
  bool committeeCanMeet = false,
  String? committeeMeetingLocation,
  TimeOfDay? committeeMeetingTime,
  String? committeeMemberId,
}) async {
  await EventService.uploadEventImage(image, societyId);

  final response = await supabase
      .from('events')
      .insert({
        'society_id': societyId,
        'event_name': name,
        'start_day': startDate.toIso8601String().split('T').first,
        'start_time':
            '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_day': endDate.toIso8601String().split('T').first,
        'end_time':
            '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
        'location': location,
        'cost': price,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'meet_committee': committeeCanMeet,
        'committee_meeting_location': committeeCanMeet
            ? committeeMeetingLocation
            : null,
        'committee_meeting_time':
            committeeCanMeet && committeeMeetingTime != null
            ? '${committeeMeetingTime.hour}:${committeeMeetingTime.minute.toString().padLeft(2, '0')}'
            : null,
        'committee_member_id': committeeCanMeet ? committeeMemberId : null,
      })
      .select('event_id')
      .single();

  return response['event_id'] as String;
}

Future<void> updateSocietyEvent({
  required String eventId,
  required String societyId,
  required String name,
  required DateTime startDate,
  required TimeOfDay startTime,
  required DateTime endDate,
  required TimeOfDay endTime,
  required String location,
  required double price,
  XFile? image,
  String? description,
  double? latitude,
  double? longitude,
  bool committeeCanMeet = false,
  String? committeeMeetingLocation,
  TimeOfDay? committeeMeetingTime,
  String? committeeMemberId,
}) async {
  if (image != null) await EventService.uploadEventImage(image, societyId);

  await supabase
      .from('events')
      .update({
        'event_name': name,
        'start_day': startDate.toIso8601String().split('T').first,
        'start_time':
            '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_day': endDate.toIso8601String().split('T').first,
        'end_time':
            '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
        'location': location,
        'cost': price,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'meet_committee': committeeCanMeet,
        'committee_meeting_location': committeeCanMeet
            ? committeeMeetingLocation
            : null,
        'committee_meeting_time':
            committeeCanMeet && committeeMeetingTime != null
            ? '${committeeMeetingTime.hour}:${committeeMeetingTime.minute.toString().padLeft(2, '0')}'
            : null,
        'committee_member_id': committeeCanMeet ? committeeMemberId : null,
      })
      .eq('event_id', eventId);
}
