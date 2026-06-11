import 'dart:io';

import 'package:drp/services/event_service.dart';
import 'package:drp/services/session_manager.dart';
import 'package:drp/services/soc_service.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/create_event.dart';

class SocietyScreen extends StatefulWidget {
  const SocietyScreen({super.key});

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> {
  String? _societyName;
  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _showArchived = false;

  final List<Map<String, String>> _events = [];

  final _aboutController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String societyId = '';

  @override
  void initState() {
    super.initState();
    _initializeSociety();
  }

  Future<void> _initializeSociety() async {
    setState(() => _isLoading = true);
    societyId = await loadUserId();
    await _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    if (societyId.isEmpty) {
      if (mounted) _showError('User session not found. Please log in again.');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch society row from your users table
      final socData = await supabase
          .from('users')
          .select()
          .eq('id', societyId)
          .maybeSingle();

      // Fetch existing events
      final eventsData = await supabase
          .from('events')
          .select()
          .eq('society_id', societyId);

      if (socData != null) {
        setState(() {
          _societyName = socData['name'] ?? '';

          _aboutController.text = socData['description'] ?? '';

          // Pre-populate avatar if one already exists
          _existingImageUrl = socData['image_url'];

          // Pre-populate events list
          _events.clear();
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          for (final e in (eventsData as List)) {
            debugPrint('Raw events data: $eventsData');
            final endDay = DateTime.tryParse(e['end_day'] ?? '');
            final isPast = endDay != null && endDay.isBefore(today);
            final entry = <String, String>{
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
              // 'latitude': '${e['latitude'] ?? ''}',
              // 'longitude': '${e['longitude'] ?? ''}',
              'latitude': e['latitude'] != null ? '${e['latitude']}' : '',
              'longitude': e['longitude'] != null ? '${e['longitude']}' : '',
              'is_past': isPast ? 'true' : 'false',
            };
            _events.add(entry);
          }

          // Sort: active events closest to now first, past events newest first
          _events.sort((a, b) {
            final aDate =
                DateTime.tryParse(a['start_day_raw']!) ?? DateTime.now();
            final bDate =
                DateTime.tryParse(b['start_day_raw']!) ?? DateTime.now();
            final aIsPast = a['is_past'] == 'true';
            final bIsPast = b['is_past'] == 'true';
            if (aIsPast != bIsPast) {
              return aIsPast ? 1 : -1;
            } // active before archived
            if (!aIsPast) {
              return aDate.compareTo(bDate);
            } // active: soonest first
            return bDate.compareTo(aDate); // archived: most recent first
          });
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError('Failed to load society profile: ${e.message}');
    } catch (e) {
      if (mounted) _showError('Unexpected error loading society profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // Method to handle editing the About Me text area via a popup dialog
  void _editAboutMe() {
    // Use a local copy so cancelling doesn't mutate state
    final tempController = TextEditingController(text: _aboutController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit About Section',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        content: TextField(
          controller: tempController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell others about your society...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context); // capture before await
              setState(
                () => _aboutController.text = tempController.text.trim(),
              );
              await updateSocDetails(
                id: societyId,
                about: _aboutController.text,
              );
              nav.pop(); // safe — no BuildContext used after async gap
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFF84DCC6),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editEvent(Map<String, String> event) async {
    final eventId = event['id'];
    debugPrint('eventId: "$eventId"');
    if (eventId == null || eventId.isEmpty) return;

    DateTime? parsedStartDate;
    TimeOfDay? parsedStartTime;
    DateTime? parsedEndDate;
    TimeOfDay? parsedEndTime;

    try {
      // Stored parsing from your format: "2026-06-09 at 16:30"
      final startParts = event['start_date']!.split(' at ');
      if (startParts.length == 2) {
        parsedStartDate = DateTime.parse(startParts[0]);
        final timeParts = startParts[1].split(':');
        parsedStartTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      // Stored parsing from your format: "2026-06-09 18:30"
      final endParts = event['end_date']!.split(' ');
      if (endParts.length == 2) {
        parsedEndDate = DateTime.parse(endParts[0]);
        final timeParts = endParts[1].split(':');
        parsedEndTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    } catch (e) {
      // Clean fallback parameters
      parsedStartDate = DateTime.now();
      parsedStartTime = const TimeOfDay(hour: 9, minute: 0);
      parsedEndDate = DateTime.now().add(const Duration(hours: 2));
      parsedEndTime = const TimeOfDay(hour: 11, minute: 0);
    }

    // Pass everything cleanly into the updated parameter structure
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
      existingDescription:
          event['description'], // Safely handled if saved in state map
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      if (result.image != null) {
        await EventService.uploadEventImage(result.image, societyId);
      }

      debugPrint('lat from result: ${result.latitude}');
      debugPrint('lng from result: ${result.longitude}');

      final updateResponse = await supabase
          .from('events')
          .update({
            'event_name': result.name,
            'start_day': result.startDate.toIso8601String().split('T').first,
            'start_time':
                '${result.startTime.hour}:${result.startTime.minute.toString().padLeft(2, '0')}',
            'end_day': result.endDate.toIso8601String().split('T').first,
            'end_time':
                '${result.endTime.hour}:${result.endTime.minute.toString().padLeft(2, '0')}',
            'location': result.location,
            'cost': result.price,
            if (result.description != null) 'description': result.description,
            if (result.latitude != null) 'latitude': result.latitude,
            if (result.longitude != null) 'longitude': result.longitude,
          })
          .eq('event_id', eventId)
          .select();

      debugPrint('update response: $updateResponse');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully!')),
        );
      }

      await _loadExistingProfile();
    } catch (e) {
      _showError('Failed to update event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSocDetails() async {
    if (!_formKey.currentState!.validate()) return;

    if (societyId.isEmpty) {
      _showError('User session not found. Please log in again.');
      setState(() => _isLoading = false); // Reset spinner
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_imageFile != null) {
        await uploadSocImage(_imageFile!, societyId);
      }

      updateSocDetails(id: societyId, about: _aboutController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated successfully!')),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('An unexpected error occurred while saving.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickSocietyImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Method placeholder for creating a new event
  void _addNewEvent() async {
    final result = await showNewEventPopup(context);
    if (result == null) return;

    // Upload image if provided, then insert into DB
    setState(() => _isLoading = true);
    try {
      await EventService.uploadEventImage(result.image, societyId);

      await supabase.from('events').insert({
        'society_id': societyId,
        'event_name': result.name,
        'start_day': result.startDate.toIso8601String().split('T').first,
        'start_time':
            '${result.startTime.hour}:${result.startTime.minute.toString().padLeft(2, '0')}',
        'end_day': result.endDate.toIso8601String().split('T').first,
        'end_time':
            '${result.endTime.hour}:${result.endTime.minute.toString().padLeft(2, '0')}',
        'location': result.location,
        'cost': result.price,
        if (result.description != null) 'description': result.description,
        if (result.latitude != null) 'latitude': result.latitude,
        if (result.longitude != null) 'longitude': result.longitude,
      });

      await _loadExistingProfile(); // refresh events list
    } catch (e) {
      _showError('Failed to create event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _eventCard(Map<String, String> event, {bool isPast = false}) {
    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Color(0X4F3E92CC),
        child: ListTile(
          onTap: isPast ? null : () => _editEvent(event),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isPast ? Colors.grey : const Color(0XFF84DCC6))
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
              "${event['start_date']} • ${event['location']}",
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

  // Logout now signs out from Supabase + confirms with user first
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Any unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Sign out from Supabase so StreamBuilder in main.dart reacts
    await supabase.auth.signOut();
    await SessionManager.clearSession();

    if (mounted) Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F6),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0XFF84DCC6),
        foregroundColor: const Color(0XFF222222),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0XFF222222),
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Details',
                  onPressed: _saveSocDetails,
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // 1. Society Picture Slot with Image rendering logic
              GestureDetector(
                onTap: _pickSocietyImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      // Logic checks: 1. Newly selected local file -> 2. Network URL from DB -> 3. Default Icon
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_existingImageUrl != null &&
                                _existingImageUrl!.isNotEmpty)
                          ? NetworkImage(_existingImageUrl!) as ImageProvider
                          : null,
                      child:
                          (_imageFile == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty))
                          ? const Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 4,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF4D5359),
                        child: Icon(
                          Icons.add_a_photo,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Society Title Name Display
              Text(
                _societyName ?? 'UNKNOWN',
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF222222),
                ),
              ),
              const SizedBox(height: 24),

              // -- about the soc --
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color(0X5F79C99E),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "ABOUT THE SOCIETY",
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Color(0xFF4D5359),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF4D5359),
                            ),
                            onPressed: _editAboutMe,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aboutController.text.isNotEmpty
                            ? _aboutController.text
                            : "No description provided yet. Click the edit icon to write something!",
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: Color(0x9F4D5359),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // -- your events --
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOUR EVENTS',
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0XFF222222),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewEvent,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("New Event"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4D5359),
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Active events ──────────────────────────────────────────
              Builder(
                builder: (_) {
                  final active = _events
                      .where((e) => e['is_past'] != 'true')
                      .toList();
                  final archived = _events
                      .where((e) => e['is_past'] == 'true')
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (active.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "No upcoming events. Tap + New Event to add one.",
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.grey,
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
                              _eventCard(active[index]),
                        ),

                      // ── Archived toggle ────────────────────────────────────
                      if (archived.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              setState(() => _showArchived = !_showArchived),
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
                  );
                },
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isLoading ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0XFFFD5757),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'LOG OUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
