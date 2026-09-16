import 'package:flutter/material.dart';

/// Drivers shown on the character page and as moving sidewalk people.
class DriverSpec {
  const DriverSpec({
    required this.id,
    required this.name,
    required this.role,
    required this.suit,
    required this.accent,
    required this.hair,
    required this.skin,
    required this.line,
    required this.mission,
  });

  final String id;
  final String name;
  final String role;
  final Color suit;
  final Color accent;
  final Color hair;
  final Color skin;
  final String line;
  final String mission;
}

class DriverCatalog {
  DriverCatalog._();

  static const List<DriverSpec> all = [
    DriverSpec(
      id: 'ace',
      name: 'Ace',
      role: 'Highway lead',
      suit: Color(0xFFE63946),
      accent: Color(0xFFFFD166),
      hair: Color(0xFF1B1B1B),
      skin: Color(0xFFE0B48A),
      line: 'I know every signal on this strip. Keep the line. Do not stop.',
      mission: 'Run the night route. Stay on the blue line until the pin.',
    ),
    DriverSpec(
      id: 'nova',
      name: 'Nova',
      role: 'Night runner',
      suit: Color(0xFF14AABC),
      accent: Color(0xFFE8F6F8),
      hair: Color(0xFF3D2314),
      skin: Color(0xFFC68642),
      line: 'Lights go green, we go. The city is awake and the clock is not.',
      mission: 'Cross the city before the window closes. Follow each road name.',
    ),
    DriverSpec(
      id: 'shade',
      name: 'Shade',
      role: 'City drift',
      suit: Color(0xFF1D3557),
      accent: Color(0xFFA8DADC),
      hair: Color(0xFF111111),
      skin: Color(0xFF8D5524),
      line: 'Corners tell you the story. Listen to the turn, then commit.',
      mission: 'Read every turn. The map is the job. Miss a road and you miss the drop.',
    ),
    DriverSpec(
      id: 'luna',
      name: 'Luna',
      role: 'Coast cruise',
      suit: Color(0xFF7B2CBF),
      accent: Color(0xFFFFB4A2),
      hair: Color(0xFF2B1B12),
      skin: Color(0xFFF1C9A0),
      line: 'South is the coast. Hold the wheel when Anna Salai opens up.',
      mission: 'Take the southern roads to the coast. Smooth, fast, no drama.',
    ),
    DriverSpec(
      id: 'bolt',
      name: 'Bolt',
      role: 'Sprint lead',
      suit: Color(0xFF2D6A4F),
      accent: Color(0xFFB7E4C7),
      hair: Color(0xFF4A3728),
      skin: Color(0xFFD4A574),
      line: 'Short gap, long city. Gas on the straight. Brake only to live.',
      mission: 'Sprint the full route. Finish at the red pin. That is the only cutscene that matters.',
    ),
  ];

  static DriverSpec byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return all.first;
  }

  static int indexOf(String id) {
    final i = all.indexWhere((d) => d.id == id);
    return i < 0 ? 0 : i;
  }
}
