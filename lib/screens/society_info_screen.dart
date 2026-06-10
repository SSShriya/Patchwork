import 'package:drp/models/event_card.dart';
import 'package:drp/models/match_card.dart';
import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:drp/screens/event_profile_screen.dart';
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
  String _about = '';
  String _location = '';
  String _imageUrl = '';
  bool _isLoading = false;
  MatchCard? _societyCard;

  final EventService eventService = EventService();

  @override
void initState() {
  super.initState();
  if (widget.societyId.isNotEmpty) {
    _loadScreenData();
  }
}

// New consolidated sequential method
Future<void> _loadScreenData() async {
  setState(() => _isLoading = true);
  
  await _setupEvents();      // 1. Fully load events first
  await _getSocietyInfo();   // 2. Then load society info using those events
  
  if (mounted) {
    setState(() => _isLoading = false);
  }
}

Future<void> _setupEvents() async {
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
    debugPrint("Error fetching events: $e");
  }
}

 Future<void> _getSocietyInfo() async {
  // Removed the extra setState updating _isLoading here, 
  // because _loadScreenData() already handles it cleanly!

  try {
    final data = await getSocDetails(widget.societyId);
    if (data == null) return;
    
    if (mounted) {
      setState(() {
        // Use ?? '' fallback to safely catch null values from your database map
        _name = data['name'] ?? 'Unknown Society';
        _uni = data['uni'] ?? '';
        _about = data['about'] ?? '';
        _location = data['location'] ?? '';
        _imageUrl = data['image_url'] ?? '';

        _societyCard = MatchCard(
          id: widget.societyId,
          title: _name,
          university: _uni,
          course: 'N/A',
          bio: _about, 
          eventId: _events.isNotEmpty ? (_events[0].eventId ?? 'N/A') : 'N/A', 
          eventName: _events.isNotEmpty ? (_events[0].title ?? 'N/A') : 'N/A',
          yearGroup: 'N/A',
          location: _location,
          interests: [],
          imageUrl: _imageUrl,
        );
      });
    }
  } catch (e) {
    debugPrint("Error fetching society info: $e");
  }
  // Removed the finally block here as well, let _loadScreenData manage state lifecycle!
}
  void _openEventSummary(EventCard card) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EventProfileScreen(card: card),
    ),
  );
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
                        '${_uni.isEmpty ? 'University not listed' : _uni} · ${_location.isEmpty ? 'London' : _location}',
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
ElevatedButton(
  onPressed: (_isLoading || _societyCard == null)
      ? null 
      : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DMScreen(
                chat: ChatConversation(matchCard: _societyCard!, isSociety: true),
              ),
            ),
          );
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0XFF84DCC6),
    foregroundColor: Colors.black,
  ),
  child: Text((_isLoading || _societyCard == null) ? "Loading..." : "Message"),
),
                  ],
                ),
                
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── About ──
          _Card(
            color: const Color(0XFFC0EDF7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _about.isEmpty ? 'No description provided for $_name.' : _about, 
                  style: const TextStyle(fontSize: 16)
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

// ── Events section ──
_Card(
  color: const Color(0X8FE6AACE),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Events:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _events.isEmpty
              ? const Text('No events listed.')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final event = _events[i];
                    return InkWell(
                      onTap: () => _openEventSummary(event),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: event.imageUrl.isNotEmpty
                                  ? Image.network(
                                      event.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: const Color(0XFFC0EDF7),
                                      child: const Icon(Icons.event, color: Colors.white),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (event.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      event.subtitle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black38),
                          ],
                        ),
                      ),
                    );
                  },
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