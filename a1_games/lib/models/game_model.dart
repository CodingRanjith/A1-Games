import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import 'game_type.dart';

class GameModel {
  const GameModel({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.difficulty,
    required this.category,
    required this.color,
    this.bestScore = 0,
    this.gamesPlayed = 0,
    this.isUnlocked = true,
    this.tagline = '',
  });

  final GameType type;
  final String name;
  final String description;
  final IconData icon;
  final GameDifficulty difficulty;
  final GameCategory category;
  final Color color;
  final int bestScore;
  final int gamesPlayed;
  final bool isUnlocked;
  final String tagline;

  String get id => type.id;

  GameModel copyWith({
    int? bestScore,
    int? gamesPlayed,
    bool? isUnlocked,
  }) {
    return GameModel(
      type: type,
      name: name,
      description: description,
      icon: icon,
      difficulty: difficulty,
      category: category,
      color: color,
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      tagline: tagline,
    );
  }
}

class GameCatalog {
  GameCatalog._();

  static const List<GameModel> games = [
    GameModel(
      type: GameType.carRace,
      name: 'Route Racer',
      description: 'Pick a car, set From → To, finish the live map route to win.',
      tagline: 'Highway drive · Finish to win',
      icon: Icons.directions_car_filled_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.arcade,
      color: AppColors.gameCarRace,
    ),
  ];

  static GameModel byType(GameType type) {
    return games.firstWhere((g) => g.type == type);
  }

  static List<GameModel> byCategory(GameCategory category) {
    if (category == GameCategory.all) return games;
    return games.where((g) => g.category == category).toList();
  }
}
