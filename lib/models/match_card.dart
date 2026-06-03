import 'package:flutter/material.dart';
import 'base_card.dart';

class MatchCard extends BaseCard {
  final String id; // from Supabase
  @override
  final String title;
  final String university;
  final String course;
  final String bio;
  final String eventId;
  final String eventName;
  final String yearGroup;
  final List<String> interests;

  const MatchCard({
    required this.id,
    required this.title,
    required this.university,
    required this.course,
    required this.bio,
    required this.eventId,
    required this.eventName,
    required this.yearGroup,
    required this.interests,
  });

  factory MatchCard.fromJson(Map<String, dynamic> json) => MatchCard(
    id: json['id'],
    title: json['name'],
    university: json['university'],
    course: json['course'],
    bio: json['bio'],
    eventId: json['event_id'],
    eventName: json['event_name'],
    yearGroup: json['year_group'] ?? '',
    interests: (json['user_interests'] as List<dynamic>? ?? [])
        .map((i) => i['interest'] as String)
        .toList(),
  );

  // So InteractiveCard still works
  String get name => title;
  @override
  IconData get icon => Icons.person;
  @override
  Color get color => const Color(0XFFEEC0C6);
}
