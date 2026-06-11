import 'package:drp/services/match_service.dart';
import 'package:flutter/material.dart';
import '../models/match_card.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../screens/dm_individual_screen.dart';
import '../models/match_convo.dart';
import '../services/event_service.dart';
import '../models/event_card.dart';
import 'package:intl/intl.dart';
import '../screens/event_profile_screen.dart';

class UserProfileCard extends StatefulWidget {
  final MatchCard card;
  final bool accepted;

  const UserProfileCard({super.key, required this.card, this.accepted = false});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  late Future<List<EventCard>> _otherEventsFuture;

  @override
  void initState() {
    super.initState();
    _otherEventsFuture = EventService().otherUserEvents(
      widget.card.currentUserId,
      widget.card.otherUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile card ──────────────────────────────────────────────
          _Card(
            child: Column(
              children: [
                ProfilePicture(
                  name: widget.card.title,
                  radius: 60,
                  fontsize: 48,
                  random: false,
                  img: widget.card.imageUrl.isNotEmpty
                      ? widget.card.imageUrl
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.card.yearGroup != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 17),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          widget.card.yearGroup,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance, size: 17),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        widget.card.university,
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
                if (widget.card.course != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.library_books, size: 17),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          widget.card.course,
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
                const SizedBox(height: 10),
                if (widget.card.location != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 17),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          widget.card.location,
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
                if (widget.accepted) const SizedBox(height: 14),
                if (widget.accepted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DMScreen(
                                chat: ChatConversation(matchCard: widget.card),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            197,
                            199,
                            162,
                            251,
                          ),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Message"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DMScreen(
                                chat: ChatConversation(matchCard: widget.card),
                                suggestMeeting: true,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            197,
                            199,
                            162,
                            251,
                          ),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Invite to Meet"),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Shared event ──────────────────────────────────────────────
          _Card(
            color: const Color(0X8FE6AACE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You both want to attend:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.card.eventName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF344966),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Interests ──
          _buildInterests(),

          const SizedBox(height: 12),

          // ── Photo Gallery ──
          _buildGallery(context),

          if (widget.card.interestPhotos.isNotEmpty) const SizedBox(height: 12),

          // ── Bio ───────────────────────────────────────────────────────
          _Card(
            color: const Color.fromARGB(255, 221, 226, 243),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bio:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.card.bio, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Other Interested Events ───────────────────────────────────
          FutureBuilder<List<EventCard>>(
            future: _otherEventsFuture,
            builder: (context, snapshot) {
              debugPrint('=== snapshot state: ${snapshot.connectionState} ===');
              debugPrint('=== snapshot error: ${snapshot.error} ===');
              debugPrint('=== snapshot data: ${snapshot.data} ===');

              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildOtherEvents(context, snapshot.data!);
            },
          ),

          const SizedBox(height: 20),

          // ── Block button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmBlock(context),
              icon: const Icon(Icons.block, color: Colors.red),
              label: const Text(
                'Block User',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Report button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _report(context),
              icon: const Icon(Icons.report, color: Colors.red),
              label: const Text(
                'Report User',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Interests card ────────────────────────────────────────────────────────
  Widget _buildInterests() {
    return _Card(
      color: const Color(0X8FBFCC94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          ...widget.card.interests.map(
            (interest) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('★ ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      interest[0].toUpperCase() + interest.substring(1),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Polaroid photo gallery card ───────────────────────────────────────────
  Widget _buildGallery(BuildContext context) {
    if (widget.card.interestPhotos.isEmpty) return const SizedBox.shrink();

    final photoInterests = widget.card.interests
        .where((i) => widget.card.interestPhotos.containsKey(i))
        .toList();

    if (photoInterests.isEmpty) return const SizedBox.shrink();

    return _Card(
      color: const Color.fromARGB(167, 255, 213, 166),

      //color: const Color.fromARGB(202, 255, 229, 181),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoInterests.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final interest = photoInterests[index];
                final photoUrl = widget.card.interestPhotos[interest]!;
                final displayName =
                    interest[0].toUpperCase() + interest.substring(1);

                return GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(context, photoUrl, interest),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF84DCC6),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, _, _) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey.shade400,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          child: Text(
                            displayName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Other interested events card ──────────────────────────────────────────
  Widget _buildOtherEvents(BuildContext context, List<EventCard> events) {
    return _Card(
      color: const Color.fromARGB(167, 232, 211, 253),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other Current/Past Events:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _OtherEventCard(
                event: events[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventProfileScreen(card: events[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Full screen image viewer ──────────────────────────────────────────────
  void _showFullScreenImage(
    BuildContext context,
    String photoUrl,
    String interest,
  ) {
    final displayName = interest[0].toUpperCase() + interest.substring(1);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF84DCC6),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBlock(BuildContext context) async {
    try {
      await MatchService().blockUser(widget.card);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to block: $e')));
      }
    }
  }

  void _confirmBlock(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user?'),
        content: Text(
          'You won\'t be matched with ${widget.card.title} again. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleBlock(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _report(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    bool blockUser = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Report user?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please describe why you\'re reporting ${widget.card.title}.',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Enter description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioGroup<bool>(
                        groupValue: blockUser,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => blockUser = value);
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<bool>(
                              value: false,
                              title: const Text('Report'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            const Divider(height: 1),
                            RadioListTile<bool>(
                              value: true,
                              title: const Text('Report and Block'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a description')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _handleReport(
                  context,
                  descriptionController.text.trim(),
                  blockUser: blockUser,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReport(
    BuildContext context,
    String description, {
    bool blockUser = false,
  }) async {
    try {
      await MatchService().reportUser(widget.card, description);
      if (blockUser) await MatchService().blockUser(widget.card);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              blockUser
                  ? 'User reported and blocked'
                  : 'User reported successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to report: $e')));
      }
    }
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

class _OtherEventCard extends StatelessWidget {
  final EventCard event;
  final VoidCallback onTap;

  const _OtherEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM').format(event.startDateTime);
    final time =
        '${DateFormat('HH:mm').format(event.startDateTime)}–${DateFormat('HH:mm').format(event.endDateTime)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(216, 247, 229, 151),

          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date chip ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color.fromARGB(180, 180, 220, 255),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$date  ·  $time',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF344966),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // ── Event name ─────────────────────────────────────────
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),

            // ── Subtitle ───────────────────────────────────────────
            Text(
              event.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
