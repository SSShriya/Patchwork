import 'package:flutter/material.dart';
import '../models/match_card.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class UserProfileCard extends StatelessWidget {
  final MatchCard card;

  const UserProfileCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name + info ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePicture(
                name: card.title,
                radius: 40,
                fontsize: 32,
                random: false,
                img: card.imageUrl.isNotEmpty ? card.imageUrl : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.school, size: 17),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${card.yearGroup} · ${card.university} · ${card.course}',
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
                      children: [
                        const Icon(Icons.location_on, size: 17),
                        Text(
                          card.location,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Shared event ──
          const Text(
            'You both want to attend:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            card.eventName.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5DA9E9),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // ── Interests ──
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

          const SizedBox(height: 24),

          // ── Bio ──
          const Text(
            'Bio:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(card.bio, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
