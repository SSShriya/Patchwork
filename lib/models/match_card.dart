import 'package:flutter/material.dart';
import 'base_card.dart';

class MatchCard extends BaseCard {
  final String currentUserId;
  final String otherUserId;
  @override
  final String title;
  final String university;
  final String course;
  final String bio;
  final String eventId;
  final String eventName;
  final String yearGroup;
  final String location;
  final List<String> interests;
  @override
  final String imageUrl; // profile image URL, can be empty if no image
  final Map<String, String> interestPhotos; // {interest: photo_url}

  const MatchCard({
    required this.currentUserId,
    required this.otherUserId,
    required this.title,
    required this.university,
    required this.course,
    required this.bio,
    required this.eventId,
    required this.eventName,
    required this.yearGroup,
    required this.location,
    required this.interests,
    required this.imageUrl,
    this.interestPhotos = const {},
  });

  // needs to be ordered the same way as the DB (user1_id < user2_id presumably)
  String get matchKey {
    final a = currentUserId.compareTo(otherUserId) <= 0
        ? currentUserId
        : otherUserId;
    final b = currentUserId.compareTo(otherUserId) <= 0
        ? otherUserId
        : currentUserId;
    return '$a|$b|$eventId';
  }

  // So InteractiveCard still works
  String get name => title;
  @override
  IconData get icon => Icons.person;
  @override
  Color get color => const Color(0XFFffb3c6);
}
