enum GameType {
  carRace,
  colorMatch,
  numberMerge,
  memoryCards,
  wordHunt,
  movieFinder,
  bubbleShooter,
  birdHit,
  fastMath,
  citySurvival,
}

enum GameDifficulty { easy, medium, hard }

enum GameCategory { all, quick, puzzle, arcade, word }

extension GameTypeX on GameType {
  String get id {
    switch (this) {
      case GameType.carRace:
        return 'car_race';
      case GameType.colorMatch:
        return 'color_match';
      case GameType.numberMerge:
        return 'number_merge';
      case GameType.memoryCards:
        return 'memory_cards';
      case GameType.wordHunt:
        return 'word_hunt';
      case GameType.movieFinder:
        return 'movie_finder';
      case GameType.bubbleShooter:
        return 'bubble_shooter';
      case GameType.birdHit:
        return 'bird_hit';
      case GameType.fastMath:
        return 'fast_math';
      case GameType.citySurvival:
        return 'city_survival';
    }
  }

  static GameType fromId(String id) {
    switch (id) {
      case 'tap_ball':
      case 'car_race':
        return GameType.carRace;
      case 'stack_blocks':
      case 'bubble_pop':
        return GameType.bubbleShooter;
      case 'avoid_obstacles':
      case 'quick_tap':
        return GameType.birdHit;
      case 'target_hit':
      case 'city_survival':
        return GameType.citySurvival;
      default:
        return GameType.values.firstWhere(
          (e) => e.id == id,
          orElse: () => GameType.carRace,
        );
    }
  }
}

extension GameDifficultyX on GameDifficulty {
  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }
}

extension GameCategoryX on GameCategory {
  String get label {
    switch (this) {
      case GameCategory.all:
        return 'All';
      case GameCategory.quick:
        return 'Quick';
      case GameCategory.puzzle:
        return 'Puzzle';
      case GameCategory.arcade:
        return 'Arcade';
      case GameCategory.word:
        return 'Word';
    }
  }
}
