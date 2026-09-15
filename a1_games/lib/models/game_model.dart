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
      name: 'City Racer',
      description: 'Pick a car, dodge traffic, race night cities.',
      tagline: 'Garage · Nitro · Night cities',
      icon: Icons.directions_car_filled_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.arcade,
      color: AppColors.gameCarRace,
    ),
    GameModel(
      type: GameType.colorMatch,
      name: 'Color Match',
      description: 'Match color + shape as fast as you can.',
      tagline: 'Brain warm-up',
      icon: Icons.palette_rounded,
      difficulty: GameDifficulty.easy,
      category: GameCategory.quick,
      color: AppColors.gameColorMatch,
    ),
    GameModel(
      type: GameType.numberMerge,
      name: 'Number Merge',
      description: 'Swipe and merge numbers to climb high.',
      tagline: 'Classic puzzle',
      icon: Icons.grid_view_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.puzzle,
      color: AppColors.gameNumberMerge,
    ),
    GameModel(
      type: GameType.memoryCards,
      name: 'Memory Cards',
      description: 'Flip cards and find every matching pair.',
      tagline: 'Train your memory',
      icon: Icons.style_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.puzzle,
      color: AppColors.gameMemory,
    ),
    GameModel(
      type: GameType.wordHunt,
      name: 'Word Hunt',
      description: 'Find hidden words in English & Tamil grids.',
      tagline: 'தமிழ் + English',
      icon: Icons.abc_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.word,
      color: AppColors.gameWordHunt,
    ),
    GameModel(
      type: GameType.movieFinder,
      name: 'Movie Finder',
      description: 'Guess the movie from emojis & clues.',
      tagline: 'Cinema quiz',
      icon: Icons.movie_filter_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.word,
      color: AppColors.gameMovieFinder,
    ),
    GameModel(
      type: GameType.bubbleShooter,
      name: 'Bubble Shooter',
      description: 'Aim, shoot & clear matching bubbles.',
      tagline: 'Arcade classic',
      icon: Icons.bubble_chart_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.arcade,
      color: AppColors.gameBubbleShooter,
    ),
    GameModel(
      type: GameType.birdHit,
      name: 'Bird Hit',
      description: 'Tap flying birds before they escape.',
      tagline: 'Sky hunter',
      icon: Icons.flutter_dash,
      difficulty: GameDifficulty.easy,
      category: GameCategory.arcade,
      color: AppColors.gameBirdHit,
    ),
    GameModel(
      type: GameType.fastMath,
      name: 'Fast Math',
      description: 'Solve equations against the clock.',
      tagline: 'Daily brain gym',
      icon: Icons.calculate_rounded,
      difficulty: GameDifficulty.medium,
      category: GameCategory.puzzle,
      color: AppColors.gameFastMath,
    ),
    GameModel(
      type: GameType.citySurvival,
      name: 'City Survival',
      description: 'Move, fight zombies. City streets → dark forest.',
      tagline: 'Niko + Blue Bot · Original',
      icon: Icons.nightlife_rounded,
      difficulty: GameDifficulty.hard,
      category: GameCategory.arcade,
      color: AppColors.gameCitySurvival,
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
