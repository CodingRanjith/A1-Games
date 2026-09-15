enum WordHuntLanguage { english, tamil }

extension WordHuntLanguageX on WordHuntLanguage {
  String get label {
    switch (this) {
      case WordHuntLanguage.english:
        return 'English';
      case WordHuntLanguage.tamil:
        return 'தமிழ்';
    }
  }

  int get gridSize {
    switch (this) {
      case WordHuntLanguage.english:
        return 8;
      case WordHuntLanguage.tamil:
        return 7;
    }
  }

  int get wordCount {
    switch (this) {
      case WordHuntLanguage.english:
        return 6;
      case WordHuntLanguage.tamil:
        return 5;
    }
  }
}

class WordHuntEntry {
  const WordHuntEntry({
    required this.word,
    this.transliteration,
  });

  final String word;
  final String? transliteration;
}

class WordHuntData {
  WordHuntData._();

  static const englishWords = [
    WordHuntEntry(word: 'CAT'),
    WordHuntEntry(word: 'DOG'),
    WordHuntEntry(word: 'SUN'),
    WordHuntEntry(word: 'BOOK'),
    WordHuntEntry(word: 'TREE'),
    WordHuntEntry(word: 'FISH'),
    WordHuntEntry(word: 'BIRD'),
    WordHuntEntry(word: 'GAME'),
    WordHuntEntry(word: 'STAR'),
    WordHuntEntry(word: 'MOON'),
    WordHuntEntry(word: 'FIRE'),
    WordHuntEntry(word: 'WIND'),
    WordHuntEntry(word: 'RAIN'),
    WordHuntEntry(word: 'HOME'),
    WordHuntEntry(word: 'LOVE'),
    WordHuntEntry(word: 'LAKE'),
    WordHuntEntry(word: 'ROAD'),
    WordHuntEntry(word: 'MILK'),
    WordHuntEntry(word: 'CAKE'),
    WordHuntEntry(word: 'PLAY'),
    WordHuntEntry(word: 'BLUE'),
    WordHuntEntry(word: 'GOLD'),
    WordHuntEntry(word: 'KING'),
    WordHuntEntry(word: 'SHIP'),
  ];

  static const tamilWords = [
    WordHuntEntry(word: 'பூ', transliteration: 'POO'),
    WordHuntEntry(word: 'நீர்', transliteration: 'NEER'),
    WordHuntEntry(word: 'மீன்', transliteration: 'MEEN'),
    WordHuntEntry(word: 'வீடு', transliteration: 'VEEDU'),
    WordHuntEntry(word: 'கண்', transliteration: 'KAN'),
    WordHuntEntry(word: 'கை', transliteration: 'KAI'),
    WordHuntEntry(word: 'மழை', transliteration: 'MAZHAI'),
    WordHuntEntry(word: 'நிலா', transliteration: 'NILA'),
    WordHuntEntry(word: 'நெல்', transliteration: 'NEL'),
    WordHuntEntry(word: 'பால்', transliteration: 'PAAL'),
    WordHuntEntry(word: 'நலம்', transliteration: 'NALAM'),
    WordHuntEntry(word: 'அணல்', transliteration: 'ANAL'),
    WordHuntEntry(word: 'பறவை', transliteration: 'PARAVAI'),
    WordHuntEntry(word: 'சூரியன்', transliteration: 'SURIYAN'),
    WordHuntEntry(word: 'காற்று', transliteration: 'KAATRU'),
    WordHuntEntry(word: 'நதி', transliteration: 'NATHI'),
    WordHuntEntry(word: 'மலை', transliteration: 'MALAI'),
    WordHuntEntry(word: 'நகர்', transliteration: 'NAGAR'),
    WordHuntEntry(word: 'அம்மா', transliteration: 'AMMA'),
    WordHuntEntry(word: 'அப்பா', transliteration: 'APPA'),
  ];

  static const englishLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const tamilLetters =
      'அஆஇஈஉஊஎஏஐஒஓஔகஙசஜஞடணதநபமயரலவழளறன';

  static List<String> lettersFor(WordHuntLanguage language) {
    switch (language) {
      case WordHuntLanguage.english:
        return englishLetters.split('');
      case WordHuntLanguage.tamil:
        return tamilLetters.split('');
    }
  }

  static List<WordHuntEntry> entriesFor(WordHuntLanguage language) {
    switch (language) {
      case WordHuntLanguage.english:
        return englishWords;
      case WordHuntLanguage.tamil:
        return tamilWords;
    }
  }
}
