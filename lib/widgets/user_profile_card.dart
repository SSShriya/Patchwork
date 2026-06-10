import 'package:drp/services/match_service.dart';
import 'package:flutter/material.dart';
import '../models/match_card.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import '../screens/dm_individual_screen.dart';
import '../models/match_convo.dart';

class UserProfileCard extends StatelessWidget {
  final MatchCard card;
  final bool accepted;

  const UserProfileCard({super.key, required this.card, this.accepted = false});

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
                  name: card.title,
                  radius: 60,
                  fontsize: 48,
                  random: false,
                  img: card.imageUrl.isNotEmpty ? card.imageUrl : null,
                ),
                const SizedBox(height: 10),
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (card.yearGroup != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 17),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          card.yearGroup,
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
                        card.university,
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
                if (card.course != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.library_books, size: 17),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          card.course,
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
                if (card.location != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 17),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          card.location,
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
                if (accepted) const SizedBox(height: 14),
                if (accepted)
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
                                chat: ChatConversation(matchCard: card),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(197, 199, 162, 251),
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
                                chat: ChatConversation(matchCard: card),
                                suggestMeeting: true,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(197, 199, 162, 251),
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
                  card.eventName.toUpperCase(),
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

          // ── Interests + photos ────────────────────────────────────────
          _buildInterestsWithPhotos(context),

          const SizedBox(height: 12),

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
                Text(card.bio, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),

          const SizedBox(height: 16),

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
                'Report user',
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

  // ── Interests card with inline photos ────────────────────────────────────
  // Interests without a photo → plain bullet list (unchanged feel)
  // Interests with a photo    → tappable row that opens a full-screen viewer
  Widget _buildInterestsWithPhotos(BuildContext context) {
    return _Card(
      color: const Color(0X8FBFCC94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...card.interests.asMap().entries.map((entry) {
            final index = entry.key;
            final interest = entry.value;
            final photoUrl = card.interestPhotos[interest];
            final hasPhoto = photoUrl != null;
            final displayName =
                interest[0].toUpperCase() + interest.substring(1);
            final isLast = index == card.interests.length - 1;

            return Column(
              children: [
                GestureDetector(
                  onTap: hasPhoto
                      ? () => _showFullScreenImage(context, photoUrl, interest)
                      : null,
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        // ── Thumbnail or placeholder ─────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: hasPhoto
                              ? Image.network(
                                  photoUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return _photoPlaceholder(isEmpty: false);
                                  },
                                  errorBuilder: (_, _, _) =>
                                      _photoPlaceholder(isEmpty: true),
                                )
                              : _photoPlaceholder(isEmpty: true),
                        ),
                        const SizedBox(width: 12),

                        // ── Interest label ───────────────────────────────
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // ── Expand icon (only if has photo) ──────────────
                        if (hasPhoto)
                          Icon(
                            Icons.open_in_full_rounded,
                            size: 15,
                            color: Colors.grey.shade600,
                          )
                        else
                          // Keeps row widths consistent
                          const SizedBox(width: 15),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Placeholder box shown when there is no photo ─────────────────────────
  Widget _photoPlaceholder({required bool isEmpty}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isEmpty ? Icons.image_outlined : Icons.hourglass_empty,
        size: 20,
        color: Colors.black26,
      ),
    );
  }

  // ── Full screen image viewer (single photo with interest label) ───────────
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
            // ── Full screen photo ───────────────────────────────────────
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

            // ── Close button ────────────────────────────────────────────
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

            // ── Interest label overlay ──────────────────────────────────
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
      await MatchService().blockUser(card);
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
          'You won\'t be matched with ${card.title} again. This cannot be undone.',
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
        builder: ((ctx, setState) => AlertDialog(
          title: const Text('Report user?'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please describe why you\'re reporting ${card.title}.',
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
        )),
      ),
    );
  }

  Future<void> _handleReport(
    BuildContext context,
    String description, {
    bool blockUser = false,
  }) async {
    try {
      await MatchService().reportUser(card, description);
      if (blockUser) await MatchService().blockUser(card);
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
