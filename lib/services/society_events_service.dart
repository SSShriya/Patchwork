import 'dart:io';

import 'package:drp/services/event_service.dart';
import 'package:drp/services/session_manager.dart';
import 'package:drp/services/soc_service.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SocietySharedState extends ChangeNotifier {
  String societyId = '';
  String? societyName;
  String? existingImageUrl;
  File? imageFile;
  bool isLoading = false;
  bool canContact = false;

  final List<Map<String, String>> events = [];
  List<Map<String, dynamic>> committee = [];

  final aboutController = TextEditingController();

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    societyId = await loadUserId();
    await loadProfile();
  }

  Future<void> loadProfile() async {
    if (societyId.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final socData = await supabase
          .from('users')
          .select()
          .eq('id', societyId)
          .maybeSingle();

      final eventsData = await supabase
          .from('events')
          .select()
          .eq('society_id', societyId);

      final committeeData = await supabase
          .from('committee_members')
          .select()
          .eq('society_id', societyId);

      if (socData != null) {
        societyName = socData['name'] ?? '';
        aboutController.text = socData['description'] ?? '';
        existingImageUrl = socData['avatar_url'];
        canContact = socData['can_message'] ?? false;
        committee = List<Map<String, dynamic>>.from(committeeData);

        events.clear();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        for (final e in (eventsData as List)) {
          final endDay = DateTime.tryParse(e['end_day'] ?? '');
          final isPast = endDay != null && endDay.isBefore(today);
          events.add({
            'id': '${e['event_id']}',
            'title': e['event_name'] ?? '',
            'start_date':
                '${DateFormat('EEE d MMM yyyy').format(DateTime.parse(e['start_day']))} at ${DateFormat('HH:mm').format(DateTime.parse('1970-01-01T${e['start_time']}'))}',
            'end_date':
                '${DateFormat('EEE d MMM yyyy').format(DateTime.parse(e['end_day']))} at ${DateFormat('HH:mm').format(DateTime.parse('1970-01-01T${e['end_time']}'))}',
            'start_day_raw': e['start_day'] ?? '',
            'start_time_raw': e['start_time'] ?? '',
            'end_day_raw': e['end_day'] ?? '',
            'end_time_raw': e['end_time'] ?? '',
            'location': e['location'] ?? '',
            'cost': '${e['cost']}',
            'latitude': e['latitude'] != null ? '${e['latitude']}' : '',
            'longitude': e['longitude'] != null ? '${e['longitude']}' : '',
            'is_past': isPast ? 'true' : 'false',
          });
        }

        events.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['start_day_raw']!) ?? DateTime.now();
          final bDate =
              DateTime.tryParse(b['start_day_raw']!) ?? DateTime.now();
          final aIsPast = a['is_past'] == 'true';
          final bIsPast = b['is_past'] == 'true';
          if (aIsPast != bIsPast) return aIsPast ? 1 : -1;
          if (!aIsPast) return aDate.compareTo(bDate);
          return bDate.compareTo(aDate);
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfileImage(File file) async {
    imageFile = file;
    notifyListeners();
  }

  Future<void> saveDetails() async {
    isLoading = true;
    notifyListeners();
    try {
      if (imageFile != null) {
        await uploadSocImage(imageFile!, societyId);
        imageFile = null;
      }
      await updateSocDetails(id: societyId, about: aboutController.text.trim());
      await loadProfile();
    } catch (e) {
      debugPrint('Error saving details: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAbout(String text) async {
    aboutController.text = text;
    notifyListeners();
    await updateSocDetails(id: societyId, about: text);
  }

  Future<void> updateContactStatus(bool value) async {
    canContact = value;
    notifyListeners();
    try {
      await supabase
          .from('users')
          .update({'can_message': value})
          .eq('id', societyId);
    } catch (e) {
      debugPrint('Error updating can_message: $e');
    }
  }

  Future<void> addCommitteeMember(String name, String role) async {
    isLoading = true;
    notifyListeners();
    try {
      await supabase.from('committee_members').insert({
        'name': name,
        'role': role,
        'society_id': societyId,
      });
      await loadProfile();
    } catch (e) {
      debugPrint('Error adding committee member: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeCommitteeMember(dynamic id) async {
    isLoading = true;
    notifyListeners();
    try {
      await supabase.from('committee_members').delete().eq('id', id);
      await loadProfile();
    } catch (e) {
      debugPrint('Error removing committee member: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createEvent({
    required String name,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
    required String location,
    required double price,
    File? image,
    String? description,
    double? latitude,
    double? longitude,
    bool committeeCanMeet = false,
    String? committeeMeetingLocation,
    TimeOfDay? committeeMeetingTime,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      await EventService.uploadEventImage(image, societyId);

      // Insert and return the new event_id
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
            'meeting_location': committeeCanMeet
                ? committeeMeetingLocation
                : null,
            'meeting_time': committeeCanMeet && committeeMeetingTime != null
                ? '${committeeMeetingTime.hour}:${committeeMeetingTime.minute.toString().padLeft(2, '0')}'
                : null,
          })
          .select('event_id')
          .single();

      final String newEventId = response['event_id'] as String;

      // Also mark the society as interested in their own event
      await supabase.from('interested_events').insert({
        'user_id': societyId,
        'event_id': newEventId,
      });

      await loadProfile();
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required String name,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
    required String location,
    required double price,
    File? image,
    String? description,
    double? latitude,
    double? longitude,
    bool committeeCanMeet = false,
    String? committeeMeetingLocation,
    TimeOfDay? committeeMeetingTime,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
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
          })
          .eq('event_id', eventId);
      await loadProfile();
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    await SessionManager.clearSession();
  }

  @override
  void dispose() {
    aboutController.dispose();
    super.dispose();
  }
}
