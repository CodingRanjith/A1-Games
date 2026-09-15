import 'package:flutter_test/flutter_test.dart';

import 'package:a1_games/features/games/number_merge/number_merge_controller.dart';
import 'package:a1_games/features/games/fast_math/fast_math_controller.dart';
import 'package:a1_games/features/games/memory_cards/memory_cards_controller.dart';

void main() {
  group('NumberMergeController', () {
    test('starts with two tiles and zero score', () {
      final c = NumberMergeController()..startGame();
      final filled =
          c.grid.expand((r) => r).where((tile) => tile != null).length;
      expect(filled, 2);
      expect(c.score, 0);
      c.dispose();
    });

    test('merge of matching tiles increases score', () {
      final c = NumberMergeController()..startGame();
      c.grid = List.generate(4, (_) => List<MergeTile?>.filled(4, null));
      c.grid[0][0] = MergeTile(value: 2);
      c.grid[0][1] = MergeTile(value: 2);
      final moved = c.swipe(SwipeDirection.left);
      expect(moved, true);
      expect(c.grid[0][0]?.value, 4);
      expect(c.score, greaterThan(0));
      c.dispose();
    });
  });

  group('FastMathController', () {
    test('generates question with four options including answer', () {
      final c = FastMathController()..start();
      final q = c.currentQuestion;
      expect(q, isNotNull);
      expect(q!.options.length, 4);
      expect(q.options.contains(q.correctAnswer), true);
      c.dispose();
    });
  });

  group('MemoryCardsController', () {
    test('easy creates 8 cards (4 pairs)', () {
      final c = MemoryCardsController(difficulty: MemoryDifficulty.easy)
        ..startGame();
      expect(c.cards.length, 8);
      c.dispose();
    });
  });
}
