import 'package:flutter/material.dart';

class SocietyScreen extends StatefulWidget {
  const SocietyScreen({super.key});

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Text("Society support coming sooon :)")
      ],)
    );
  }
 }
 

/*
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SocietyScreen extends StatefulWidget {
  const SocietyScreen({super.key});

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> {
  // Temporary mock data for state management
  final String _societyName = "Sci-Fi";
  String _aboutText = "";
  File? _imageFile;
  
  // Dummy event list
  final List<Map<String, String>> _myEvents = [
    {"title": "Hackathon Pre-Meet", "date": "Friday, 7:00 PM", "location": "Student Union"},
    {"title": "Board Games Night", "date": "Next Tuesday, 6:30 PM", "location": "Main Quad"},
  ];

  // Method to handle editing the About Me text area via a popup dialog
  void _editAboutMe() {
    final TextEditingController aboutController = TextEditingController(text: _aboutText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit About Section', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: aboutController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Tell others about your society...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _aboutText = aboutController.text.trim();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF84DCC6)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            
            // 1. Society Picture Slot with an Edit Icon Overlay
            GestureDetector(
              onTap: _pickSocietyImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 65, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0XFF84DCC6),
                      child: const Icon(Icons.add_a_photo, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Society Title Name Display
            Text(
              _societyName,
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
                      _aboutText.isNotEmpty ? _aboutText : "No description provided yet. Click the edit icon to write something!",
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
            _myEvents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      "You haven't listed any events yet.",
                      style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true, // Crucial: Allows it to work smoothly within SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Passes scrolling touch events to parent viewport
                    itemCount: _myEvents.length,
                    itemBuilder: (context, index) {
                      final event = _myEvents[index];
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
          ],
        ),
      ),
    );
  }
}
*/