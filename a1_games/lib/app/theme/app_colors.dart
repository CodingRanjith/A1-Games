import 'package:flutter/material.dart';

/// Centralized color palette. Change here to retheme the entire app.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryLight = Color(0xFFFF8C61);
  static const Color accent = Color(0xFFFFB703);
  static const Color accentDark = Color(0xFFFB8500);

  // Surfaces — Light
  static const Color backgroundLight = Color(0xFFF7F9F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8E5);

  // Surfaces — Dark
  static const Color backgroundDark = Color(0xFF0F1A15);
  static const Color surfaceDark = Color(0xFF1A2A22);
  static const Color cardDark = Color(0xFF243530);
  static const Color dividerDark = Color(0xFF2F443A);

  // Text
  static const Color textPrimaryLight = Color(0xFF1A2A22);
  static const Color textSecondaryLight = Color(0xFF5C6F66);
  static const Color textPrimaryDark = Color(0xFFF0F5F2);
  static const Color textSecondaryDark = Color(0xFFA8BDB3);

  // Semantic
  static const Color success = Color(0xFF2D9F6F);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE63946);
  static const Color info = Color(0xFF457B9D);

  // Game accents
  static const Color gameCarRace = Color(0xFFE63946);
  static const Color gameColorMatch = Color(0xFF9B5DE5);
  static const Color gameNumberMerge = Color(0xFF00BBF9);
  static const Color gameMemory = Color(0xFFF15BB5);
  static const Color gameWordHunt = Color(0xFF2A9D8F);
  static const Color gameMovieFinder = Color(0xFFE76F51);
  static const Color gameBubbleShooter = Color(0xFF4CC9F0);
  static const Color gameBirdHit = Color(0xFF2EC4B6);
  static const Color gameFastMath = Color(0xFF4361EE);
  static const Color gameCitySurvival = Color(0xFF6A994E);

  // Legacy aliases
  static const Color gameTapBall = gameCarRace;
  static const Color gameTargetHit = gameCitySurvival;
  static const Color gameStack = gameWordHunt;
  static const Color gameAvoid = gameMovieFinder;
  static const Color gameBubble = gameBubbleShooter;
  static const Color gameQuickTap = gameBirdHit;

  // Difficulty
  static const Color difficultyEasy = Color(0xFF2D9F6F);
  static const Color difficultyMedium = Color(0xFFF4A261);
  static const Color difficultyHard = Color(0xFFE63946);
}
