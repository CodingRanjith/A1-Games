import 'dart:math';

enum MovieDifficulty { easy, medium, hard }

extension MovieDifficultyX on MovieDifficulty {
  String get label {
    switch (this) {
      case MovieDifficulty.easy:
        return 'Easy';
      case MovieDifficulty.medium:
        return 'Medium';
      case MovieDifficulty.hard:
        return 'Hard';
    }
  }
}

class MovieClue {
  const MovieClue({
    required this.emojis,
    required this.answers,
    required this.displayTitle,
    this.hint,
    this.difficulty = MovieDifficulty.medium,
  });

  final String emojis;
  final List<String> answers;
  final String displayTitle;
  final String? hint;
  final MovieDifficulty difficulty;

  bool matches(String input) {
    final normalized = input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    if (normalized.isEmpty) return false;
    for (final a in answers) {
      final ans = a.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
      if (normalized == ans) return true;
    }
    return false;
  }
}

class MovieFinderData {
  MovieFinderData._();

  static const totalRounds = 10;

  static const clues = [
    MovieClue(
      emojis: '🦁👑',
      displayTitle: 'The Lion King',
      answers: ['the lion king', 'lion king'],
      hint: 'Disney savanna royalty',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🚢🧊💔',
      displayTitle: 'Titanic',
      answers: ['titanic'],
      hint: 'Iceberg romance epic',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🕷️🦸',
      displayTitle: 'Spider-Man',
      answers: ['spider-man', 'spiderman', 'spider man'],
      hint: 'Web-slinging hero',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🦇🌃',
      displayTitle: 'The Dark Knight',
      answers: ['the dark knight', 'dark knight', 'batman'],
      hint: 'Gotham vigilante',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '🏠👦🎄',
      displayTitle: 'Home Alone',
      answers: ['home alone'],
      hint: 'Holiday mischief classic',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🦖🏝️',
      displayTitle: 'Jurassic Park',
      answers: ['jurassic park'],
      hint: 'Dinos on an island',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '❄️👸',
      displayTitle: 'Frozen',
      answers: ['frozen'],
      hint: 'Let it go!',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🚗⚡',
      displayTitle: 'Cars',
      answers: ['cars', 'lightning mcqueen', 'cars 2', 'cars 3'],
      hint: 'Pixar racing tale',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🤖🔥',
      displayTitle: 'Enthiran / Robot',
      answers: ['enthiran', 'robot', '2.0', '2 point 0'],
      hint: 'Rajini sci-fi blockbuster',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '🎪🤡',
      displayTitle: 'Joker',
      answers: ['joker', 'the joker'],
      hint: 'Clown prince of crime',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '👸🐸',
      displayTitle: 'The Princess and the Frog',
      answers: [
        'the princess and the frog',
        'princess and the frog',
      ],
      hint: 'Bayou fairy tale',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '🧙‍♂️💍',
      displayTitle: 'The Lord of the Rings',
      answers: [
        'the lord of the rings',
        'lord of the rings',
        'lotr',
      ],
      hint: 'Middle-earth quest',
      difficulty: MovieDifficulty.hard,
    ),
    MovieClue(
      emojis: '🏏🇮🇳',
      displayTitle: 'Lagaan',
      answers: ['lagaan'],
      hint: 'Cricket vs the British',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '👨‍🚀🌕',
      displayTitle: 'Interstellar',
      answers: ['interstellar'],
      hint: 'Corn fields & wormholes',
      difficulty: MovieDifficulty.hard,
    ),
    MovieClue(
      emojis: '🧞‍♂️🕌',
      displayTitle: 'Aladdin',
      answers: ['aladdin'],
      hint: 'Magic carpet ride',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🎭💃',
      displayTitle: 'Devdas',
      answers: ['devdas'],
      hint: 'Tragic love triangle',
      difficulty: MovieDifficulty.hard,
    ),
    MovieClue(
      emojis: '🐠🔍',
      displayTitle: 'Finding Nemo',
      answers: ['finding nemo', 'nemo'],
      hint: 'Just keep swimming',
      difficulty: MovieDifficulty.easy,
    ),
    MovieClue(
      emojis: '🏎️💨',
      displayTitle: 'Fast & Furious',
      answers: [
        'fast and furious',
        'fast & furious',
        'the fast and the furious',
      ],
      hint: 'Family & nitro',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '🧛🍎',
      displayTitle: 'Twilight',
      answers: ['twilight'],
      hint: 'Sparkly vampire romance',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '🎬🌟',
      displayTitle: '3 Idiots',
      answers: ['3 idiots', 'three idiots'],
      hint: 'All is well!',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '👻👻',
      displayTitle: 'Ghostbusters',
      answers: ['ghostbusters', 'ghost busters'],
      hint: 'Who you gonna call?',
      difficulty: MovieDifficulty.medium,
    ),
    MovieClue(
      emojis: '🏹👸',
      displayTitle: 'Brave',
      answers: ['brave'],
      hint: 'Red-haired archer princess',
      difficulty: MovieDifficulty.easy,
    ),
  ];

  static List<String> buildOptions(MovieClue correct, Random random) {
    final pool = clues
        .where((c) => c.displayTitle != correct.displayTitle)
        .map((c) => c.displayTitle)
        .toList()
      ..shuffle(random);

    final options = <String>[correct.displayTitle, ...pool.take(3)];
    options.shuffle(random);
    return options;
  }
}
