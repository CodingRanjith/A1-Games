/// Original low-poly human meshes. Not copied from another game.
class CharacterModels {
  CharacterModels._();

  static const idle = 'assets/models/characters/human.glb';
  static const walkA = 'assets/models/characters/human-walk-a.glb';
  static const walkB = 'assets/models/characters/human-walk-b.glb';
  static const seated = 'assets/models/characters/human-seat.glb';

  static const ids = ['ace', 'nova', 'shade', 'luna', 'bolt'];

  static String textureFor(String id) => 'assets/models/characters/Textures/$id.png';

  static String textureAt(int index) => textureFor(ids[index.abs() % ids.length]);

  static List<String> get preloadPaths => [idle, walkA, walkB, seated];
}
