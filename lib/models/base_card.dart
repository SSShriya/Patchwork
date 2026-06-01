import 'package:flutter/material.dart';

abstract class BaseCard {
  const BaseCard();

  String get title;
  IconData get icon;
  Color get color;
}
