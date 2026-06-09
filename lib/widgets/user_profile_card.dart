import 'package:drp/services/match_service.dart';
import 'package:flutter/material.dart';
import '../models/match_card.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class UserProfileCard extends StatelessWidget {
  final MatchCard card;

  const UserProfileCard({
    super.key, 
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Profile card --
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 17),
                    const SizedBox(width: 2),
                    Text(
                        '${card.yearGroup} · ${card.university} · ${card.course}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 17),
                    const SizedBox(width: 4),
                    Text(
                      card.location,
                      style: const TextStyle(fontSize: 16, color: Colors.grey,),
                    ),
                  ],
                ),
              ],
            )
          ),

          const SizedBox(height: 12),

          // ── Shared event ──
          _Card(
            color: Color(0X8FE6AACE),
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
              ]
            ),
          ),

          const SizedBox(height: 12),

          // ── Interests ──
          _Card(
            // color: Color.fromARGB(255, 221, 226, 243),
            color: Color(0X8FBFCC94),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interests:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                ...card.interests.map(
                  (interest) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('★ ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(interest, style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bio ──
          _Card(
            color: Color.fromARGB(255, 221, 226, 243),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bio:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(card.bio, style: const TextStyle(fontSize: 16)),
              ]
            )
          ),

          const SizedBox(height: 16),

          // ── Block button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmBlock(context),
              icon: const Icon(Icons.block, color: Colors.red),
              label: const Text('Block User', style: TextStyle(color: Colors.red)),
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

  Future<void> _handleBlock(BuildContext context) async {
    try {
      await MatchService().blockUser(card.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block: $e')),
        );
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
        // border: Border.all(color: Colors.grey),
      ),
      child: child,
    );
  }
}