import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/bubble_shooter_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BubblePopApp());
}

class BubblePopApp extends StatefulWidget {
  const BubblePopApp({super.key});

  @override
  State<BubblePopApp> createState() => _BubblePopAppState();
}

class _BubblePopAppState extends State<BubblePopApp> {
  late final BubbleShooterGame _game = BubbleShooterGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bubble Pop!',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: GameWidget(
          game: _game,
          overlayBuilderMap: {
            'hud': _hud,
            'pauseMenu': _pauseMenu,
            'gameOver': _gameOver,
            'levelComplete': _levelComplete,
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}

// ---------------- HUD ----------------

Widget _hud(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  return Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            _Pill(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              child: ValueListenableBuilder<int>(
                valueListenable: g.scoreNotifier,
                builder: (_, v, __) => Text(
                  '$v',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Pill(
              icon: Icons.flag_rounded,
              iconColor: Colors.lightBlueAccent,
              child: ValueListenableBuilder<int>(
                valueListenable: g.levelNotifier,
                builder: (_, v, __) => Text(
                  'Lv $v',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: g.shotsLeftNotifier,
              builder: (_, v, __) => Text(
                'New row in $v',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: g.togglePause,
              icon: const Icon(Icons.pause_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.icon, required this.iconColor, required this.child});

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          child,
        ],
      ),
    );
  }
}

// ---------------- overlays ----------------

Widget _pauseMenu(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  return _OverlayCard(
    title: 'Paused',
    children: [
      _MenuButton(
          label: 'Resume', icon: Icons.play_arrow_rounded, onTap: g.togglePause),
      const SizedBox(height: 10),
      _MenuButton(
          label: 'Restart level',
          icon: Icons.refresh_rounded,
          onTap: g.retryLevel),
    ],
  );
}

Widget _gameOver(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  return _OverlayCard(
    title: 'Game Over',
    subtitle: 'The bubbles reached the red line!',
    children: [
      Text(
        'Score: ${g.score}',
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
      ),
      const SizedBox(height: 14),
      _MenuButton(
          label: 'Try again', icon: Icons.refresh_rounded, onTap: g.retryLevel),
    ],
  );
}

Widget _levelComplete(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  return _OverlayCard(
    title: 'Level ${g.level} complete!',
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Icon(
            Icons.star_rounded,
            size: 36,
            color: i < g.stars ? Colors.amber : Colors.white24,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Score: ${g.score}',
        style: const TextStyle(fontSize: 18, color: Colors.white70),
      ),
      const SizedBox(height: 14),
      _MenuButton(
        label: 'Next level',
        icon: Icons.arrow_forward_rounded,
        onTap: g.nextLevel,
      ),
    ],
  );
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2452),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style:
                      const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4D9FFF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
