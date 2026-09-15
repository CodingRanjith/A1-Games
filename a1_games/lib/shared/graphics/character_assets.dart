/// Character backdrop assets for cinematic game / home backgrounds.
///
/// Drop your own licensed Unreal Engine-exported PNG/WebP here to override:
///   assets/characters/hero.png
///   assets/characters/bird_hunter.png
///   assets/characters/bubble_shooter.png
///   assets/characters/movie_host.png
///   assets/characters/target_hunter.png
///
/// Do NOT use copyrighted Epic/Fortnite characters without a license.
class CharacterAssets {
  CharacterAssets._();

  static const String hero = 'assets/characters/hero.png';
  static const String birdHunter = 'assets/characters/bird_hunter.png';
  static const String bubbleShooter = 'assets/characters/bubble_shooter.png';
  static const String movieHost = 'assets/characters/movie_host.png';
  static const String targetHunter = 'assets/characters/target_hunter.png';

  static String? forGameId(String gameId) {
    switch (gameId) {
      case 'bird_hit':
        return birdHunter;
      case 'bubble_shooter':
        return bubbleShooter;
      case 'movie_finder':
        return movieHost;
      case 'target_hit':
      case 'city_survival':
        return targetHunter;
      case 'tap_ball':
      case 'car_race':
      case 'color_match':
      case 'fast_math':
      case 'memory_cards':
      case 'word_hunt':
      case 'number_merge':
        return hero;
      default:
        return hero;
    }
  }
}
