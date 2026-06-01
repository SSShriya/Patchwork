import 'package:flutter/material.dart';
import 'base_card.dart';

class MatchCard extends BaseCard {
  final String id; // from Supabase
  @override
  final String title;
  @override
  final String subtitle;
  final String course;
  final String bio;
  final String event;
  final String group;
  final String yearGroup;
  final List<String> interests;

  const MatchCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.course,
    required this.bio,
    required this.event,
    required this.group,
    required this.yearGroup,
    required this.interests,
  });

  factory MatchCard.fromJson(Map<String, dynamic> json) => MatchCard(
    id: json['id'],
    title: json['name'],
    subtitle: json['university'],
    course: json['course'],
    bio: json['bio'],
    event: json['event'],
    group: json['event_group'],
    yearGroup: json['year_group'] ?? '',
    interests: (json['interests'] as List<dynamic>? ?? [])
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
