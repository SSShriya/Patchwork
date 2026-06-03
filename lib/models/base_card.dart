import 'package:flutter/material.dart';

abstract class BaseCard {
  const BaseCard();

  String get title;
  String get imageUrl;
  IconData get icon;
  Color get color;
}
