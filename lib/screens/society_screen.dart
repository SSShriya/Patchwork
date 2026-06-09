import 'dart:io';

import 'package:drp/services/session_manager.dart';
import 'package:drp/services/soc_service.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      // Fetch user row from your users table
      final socData = await supabase
          .from('societies')
          .select()
          .eq('id', societyId)
          .maybeSingle();

      // Fetch existing events
      final eventsData = await supabase
          .from('events')
          .select('event_name')
          .eq('society_id', societyId);

      if (socData != null) {
        setState(() {
          _societyName = socData['name'] ?? '';

          _aboutController.text = socData['description'] ?? '';

          // Pre-populate avatar if one already exists
          _existingImageUrl = socData['image_url'];

          // Pre-populate events list
          _events.clear();
          _events.addAll(
            (eventsData as List).map((e) => 
              {'title': e['event_name'], 
               'start_date': '${e['start_day']} ${e['start_time']}',
               'end_date': '${e['end_day']} ${e['end_time']}',
               'location': e['location'],
               'cost': e['cost']})
          );

        });
      }
    } on PostgrestException catch (e) {
      if (mounted) _showError('Failed to load society profile: ${e.message}');
    } catch (e) {
      if (mounted) _showError('Unexpected error loading society profile.');
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
      title: Text('Edit About Section', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
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
            setState(() => _aboutController.text = tempController.text.trim());
            await updateSocDetails(id: societyId, about: _aboutController.text);
            nav.pop(); // safe — no BuildContext used after async gap
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF84DCC6)),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
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
  void _addNewEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO')),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF222222)),
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
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                              ? NetworkImage(_existingImageUrl!) as ImageProvider
                              : null,
                      child: (_imageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 65, color: Colors.white)
                          : null,
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 4,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0XFF84DCC6),
                        child: Icon(Icons.add_a_photo, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
  
              // 2. Society Title Name Display
              Text(
                _societyName ?? 'UNKNOWN',
                style: GoogleFonts.lora(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0XFF222222),
                ),
              ),
              const SizedBox(height: 24),
  
              // 3. Container Card housing the "About" Description Box
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "ABOUT ME",
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Color(0xFFEBA6A9)),
                            onPressed: _editAboutMe,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aboutController.text.isNotEmpty ? _aboutController.text : "No description provided yet. Click the edit icon to write something!",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
  
              // 4. "YOUR EVENTS" Section Header with Plus Floating Action Style Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOUR EVENTS',
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0XFF222222),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewEvent,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("New Event"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0XFF84DCC6),
                      textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
  
              // 5. Scrollable Column of Event Cards
              _events.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "You haven't listed any events yet.",
                        style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0XFF84DCC6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today, color: Color(0XFF84DCC6)),
                            ),
                            title: Text(
                              event["title"]!,
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "${event['date']} • ${event['location']}",
                                style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                        onPressed: _isLoading ? null : _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFFD5757),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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