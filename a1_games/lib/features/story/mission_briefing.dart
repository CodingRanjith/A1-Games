import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../setup/character_preview.dart';
import '../setup/driver_catalog.dart';

/// GTA-style mission card. Skip drops straight into the drive.
class MissionBriefing extends StatelessWidget {
  const MissionBriefing({
    super.key,
    required this.driver,
    required this.from,
    required this.to,
    required this.roads,
    required this.distance,
    required this.eta,
    required this.onStart,
    required this.onSkip,
  });

  final DriverSpec driver;
  final String from;
  final String to;
  final List<String> roads;
  final String distance;
  final String eta;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'MISSION',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSkip();
                    },
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: CharacterPreview3d(driver: driver),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            driver.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(driver.role, style: TextStyle(color: driver.accent, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Text(
                            driver.line,
                            style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 15),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            driver.mission,
                            style: const TextStyle(color: Colors.white70, height: 1.35),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$from  →  $to',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$distance   ·   $eta',
                            style: const TextStyle(color: Color(0xFF8AB4F8), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            roads.take(4).join('  ·  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('START MISSION', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
