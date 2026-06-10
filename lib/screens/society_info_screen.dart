import 'package:drp/models/event_card.dart';
import 'package:drp/services/event_service.dart';
import 'package:drp/services/soc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class SocietyInfoScreen extends StatefulWidget {
  final String societyId;

  const SocietyInfoScreen({
    super.key,
    required this.societyId,
  });

  @override
  State<SocietyInfoScreen> createState() => _SocietyInfoScreenState();
}

class _SocietyInfoScreenState extends State<SocietyInfoScreen> {
  final List<EventCard> _events = [];
  String _name = '';
  String _uni = '';
  String? _about;
  String? _location;
  String _imageUrl = '';
  bool _isLoading = false;

  final EventService eventService = EventService();

  @override
  void initState() {
    super.initState();
    if (widget.societyId.isNotEmpty) {
      _setupEvents();
      _getSocietyInfo();
    }
  }

  Future<void> _setupEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<EventCard> events = await eventService.getAllEvents();
      events = events.where((e) => e.societyId == widget.societyId).toList();
      if (mounted) {
        setState(() {
          _events.clear();
          _events.addAll(events);
        });
      }
    } catch (e) {
      // Handle potential API errors gracefully
      debugPrint("Error fetching events: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

    Future<void> _getSocietyInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await getSocDetails(widget.societyId);
      if(data == null) return;
      if (mounted) {
        setState(() {
          _name = data['name'];
          _uni = data['uni'];
          _about = data['about'];
          _location = data['location'];
          _imageUrl = data['image_url'];
        });
      }
    } catch (e) {
      // Handle potential API errors gracefully
      debugPrint("Error fetching society info: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(_name.isEmpty ? 'Society' : _name),
    ),
    
    
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Profile card --
          _Card(
            child: Column(
              children: [
                ProfilePicture(
                  name: _name,
                  radius: 60,
                  fontsize: 48,
                  random: false,
                  img: _imageUrl.isNotEmpty ? _imageUrl : null,
                ),

                const SizedBox(height: 10),

                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 17),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_uni.isEmpty ? 'University not listed' : _uni} · ${_location ?? 'London'}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
/*
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DMScreen(
                              chat: ChatConversation(matchCard: card),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(197, 199, 162, 251),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Message"),
                    ),
                  ],
                ),
                */
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── About ──
          _Card(
            color: const Color.fromARGB(255, 221, 226, 243),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_about ?? 'No description provided for $_name.', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Events ──
          _Card(
            color: const Color(0X8FE6AACE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Events:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _events.join(", ").toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF344966),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    )
    );
  }

}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Card({
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}