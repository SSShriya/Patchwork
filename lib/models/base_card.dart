import 'package:flutter/material.dart';

abstract class BaseCard {
  const BaseCard();

  String get title;
  String get subtitle;
  IconData get icon;
  Color get color;
}
