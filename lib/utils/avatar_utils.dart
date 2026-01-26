import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Color getAvatarColor(String name) {
  return AppAvatarColors.palette[name.hashCode.abs() % AppAvatarColors.palette.length];
}
