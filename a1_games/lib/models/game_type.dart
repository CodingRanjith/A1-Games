enum GameType { carRace }

enum GameDifficulty { easy, medium, hard }

enum GameCategory { all, arcade }

extension GameTypeX on GameType {
  String get id => 'car_race';

  static GameType fromId(String id) => GameType.carRace;
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
      case GameCategory.arcade:
        return 'Arcade';
    }
  }
}
