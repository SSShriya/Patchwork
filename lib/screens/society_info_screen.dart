import 'package:drp/models/event_card.dart';
import 'package:drp/models/match_card.dart';
import 'package:drp/models/match_convo.dart';
import 'package:drp/screens/dm_individual_screen.dart';
import 'package:drp/screens/event_profile_screen.dart';
import 'package:drp/services/event_service.dart';
import 'package:drp/services/soc_service.dart';
import 'package:drp/services/supabase_client.dart';
import 'package:drp/services/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class SocietyInfoScreen extends StatefulWidget {
  final String societyId;
  final String eventId; // users can only reach this screen through an event

  const SocietyInfoScreen({
    super.key,
    required this.societyId,
    required this.eventId,
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
  late final String userId;
  final List<EventCard> _userInterestedEvents = [];

  final EventService eventService = EventService();

  @override
  void initState() {
    super.initState();
    if (widget.societyId.isNotEmpty) {
      _loadScreenData();
    }
  }

  // Consolidated parallel loader
  Future<void> _loadScreenData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch user ID first since checking interested events depends on it
      userId = await loadUserId();

      // Run independent network requests concurrently to optimize performance
      await Future.wait([
        _setupEvents(),
        _getSocietyInfo(),
        _checkUserInterestedEvents(),
      ]);

      // Re-build society card if events loaded successfully to ensure event data is linked
      if (_name.isNotEmpty && _societyCard == null) {
        _buildSocietyCard();
      }
    } catch (e) {
      debugPrint("Error initializing screen data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _checkUserInterestedEvents() async {
    try {
      List<EventCard> interestedEvents = await eventService.getInterestedEvents(
        userId,
      );
      if (mounted) {
        setState(() {
          _userInterestedEvents.clear();
          _userInterestedEvents.addAll(interestedEvents);
        });
      }
    } catch (e) {
      debugPrint("Error fetching user's interested events: $e");
    }
  }

  Future<void> _getSocietyInfo() async {
    try {
      final data = await getSocDetails(widget.societyId);
      if (data == null) return;

      if (mounted) {
        setState(() {
          _name = data['name'] ?? 'Unknown Society';
          _uni = data['uni'] ?? '';
          _about = data['about'] ?? '';
          _location = data['location'] ?? '';
          _imageUrl = data['image_url'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching society info: $e");
    }
  }

  void _buildSocietyCard() {
    _societyCard = MatchCard(
      title: _name,
      university: _uni,
      course: 'N/A',
      bio: _about,
      eventId: _events.isNotEmpty ? _events[0].eventId : 'N/A',
      eventName: _events.isNotEmpty ? _events[0].title : 'N/A',
      yearGroup: 'N/A',
      location: _location,
      interests: const [],
      imageUrl: _imageUrl,
      currentUserId: userId,
      otherUserId: widget.societyId,
    );
  }

  void _openEventSummary(EventCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventProfileScreen(card: card)),
    );
  }

  Future<void> _initiateSocietyChat() async {
    await supabase.from('matches').upsert({
      'user1_id': widget.societyId,
      'user2_id': userId,
      'event_id': widget.eventId,
      'user1_accepted': true,
      'user2_accepted': true,
    }, onConflict: 'user1_id,user2_id,event_id');
  }

  // Helper check to see if the event item collection contains our current target ID
  bool _isUserInterestedInCurrentEvent() {
    return _userInterestedEvents.any(
      (element) => element.eventId == widget.eventId,
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
                        onPressed:
                            (_isLoading ||
                                _societyCard == null ||
                                !_isUserInterestedInCurrentEvent())
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await _initiateSocietyChat();
                                if (!mounted) return;

                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) => DMScreen(
                                      chat: ChatConversation(
                                        matchCard: _societyCard!,
                                        isSociety: true,
                                      ),
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFF84DCC6),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          (_isLoading || _societyCard == null)
                              ? "Loading..."
                              : (_isUserInterestedInCurrentEvent()
                                    ? "Message"
                                    : "Express interest in an event to message!"),
                        ),
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
                    _about.isEmpty
                        ? 'No description provided for $_name.'
                        : _about,
                    style: const TextStyle(fontSize: 16),
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
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                                              child: const Icon(
                                                Icons.event,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black38,
                                    ),
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
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Card({required this.child, this.color});

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
