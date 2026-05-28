import 'package:flutter/material.dart';
import 'base_card.dart';

class AppCard extends BaseCard {
  @override
  final String title;
  @override
  final String subtitle;
  @override
  final IconData icon;
  @override
  final Color color;

  const AppCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// dummy cards
const recCards = [
  AppCard(
    title: 'Cookie Making',
    subtitle: 'Baking Society',
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
  AppCard(
    title: 'Fight Club',
    subtitle: 'Boxing Society',
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
  AppCard(
    title: 'Listening Party',
    subtitle: 'Alternative Music Society',
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
  AppCard(
    title: 'Off the Hook',
    subtitle: 'KnitSock',
    icon: Icons.cloud,
    color: Color(0XFFFED766),
  ),
];
