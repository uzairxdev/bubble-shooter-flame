import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/bubble_shooter_game.dart';
import 'game/save_data.dart';
import 'game/sfx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveData.init();
  GameSettings.load();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BubblePopApp());
}

class BubblePopApp extends StatelessWidget {
  const BubblePopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bubble Pop!',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainMenuScreen(),
    );
  }
}

// ================= main menu =================

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final todayKey = SaveData.dateKey(DateTime.now());
    final dailyBest = SaveData.dailyBest(todayKey);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          Container(color: Colors.black45),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 36),
                const Text(
                  'BUBBLE POP!',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 12,
                          color: Colors.black87,
                          offset: Offset(0, 4)),
                      Shadow(
                          blurRadius: 24,
                          color: Color(0xAA4D9FFF),
                          offset: Offset.zero),
                    ],
                  ),
                ),
                const Text(
                  'aim • match • pop',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Image.asset('assets/images/mascot.png', height: 190),
                const Spacer(),
                _BigButton(
                  label: 'Play',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF4D9FFF),
                  onTap: () => Navigator.of(context)
                      .push(
                          MaterialPageRoute(builder: (_) => const LevelSelectScreen()))
                      .then((_) => setState(() {})),
                ),
                const SizedBox(height: 12),
                _BigButton(
                  label: dailyBest > 0
                      ? 'Daily Challenge  •  best $dailyBest'
                      : 'Daily Challenge',
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFFB366FF),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const GameScreen(
                              level: 1, mode: GameMode.daily)))
                      .then((_) => setState(() {})),
                ),
                const SizedBox(height: 12),
                _BigButton(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  color: const Color(0xFF5A6B8C),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const SettingsScreen()))
                      .then((_) => setState(() {})),
                ),
                const Spacer(),
                Text(
                  '🔥 Best combo x${SaveData.bestCombo}    •    🏆 ${SaveData.totalWins} wins',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Sfx.play('click.wav');
            onTap();
          },
          icon: Icon(icon, size: 26),
          label: Text(label, style: const TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
          ),
        ),
      ),
    );
  }
}

// ================= level select =================

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = SaveData.unlockedLevel;
    final count = unlocked.clamp(12, 120);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose level'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: count,
        itemBuilder: (context, i) {
          final level = i + 1;
          final isOpen = level <= unlocked;
          final stars = SaveData.stars(level);
          final best = SaveData.bestScore(level);
          return GestureDetector(
            onTap: isOpen
                ? () {
                    Sfx.play('click.wav');
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GameScreen(level: level)));
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFF1B2452) : Colors.white10,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isOpen ? const Color(0xFF4D9FFF) : Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isOpen
                      ? Text('$level',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold))
                      : const Icon(Icons.lock_rounded,
                          color: Colors.white38, size: 22),
                  if (isOpen) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (s) => Icon(Icons.star_rounded,
                            size: 12,
                            color: s < stars
                                ? Colors.amber
                                : Colors.white24),
                      ),
                    ),
                    if (best > 0)
                      Text('$best',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white60)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= settings =================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
            'This clears every best score, star, unlock, and setting.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      await SaveData.resetAll();
      GameSettings.load();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress reset.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: GameSettings.sound,
            builder: (_, v, __) => SwitchListTile(
              title: const Text('Sound effects'),
              secondary: const Icon(Icons.volume_up_rounded),
              value: v,
              onChanged: (nv) {
                GameSettings.updateSound(nv);
                if (nv) Sfx.play('click.wav');
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: GameSettings.vibration,
            builder: (_, v, __) => SwitchListTile(
              title: const Text('Vibration'),
              secondary: const Icon(Icons.vibration_rounded),
              value: v,
              onChanged: GameSettings.updateVibration,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: GameSettings.colorblind,
            builder: (_, v, __) => SwitchListTile(
              title: const Text('Colorblind-friendly palette'),
              subtitle:
                  const Text('Swaps bubble colors for an accessible set'),
              secondary: const Icon(Icons.palette_rounded),
              value: v,
              onChanged: GameSettings.updateColorblind,
            ),
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            title: const Text('Reset all progress',
                style: TextStyle(color: Colors.redAccent)),
            onTap: _confirmReset,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Bubble Pop! v1.0\nOriginal game by Muhammad Uzair • uzairxdev.online',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= game screen =================

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level, this.mode = GameMode.endless});

  final int level;
  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BubbleShooterGame _game = BubbleShooterGame(
    startLevel: widget.level,
    mode: widget.mode,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            if (g.isDaily)
              const _Pill(
                icon: Icons.calendar_today_rounded,
                iconColor: Colors.purpleAccent,
                child: Text('DAILY',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              )
            else
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
            const SizedBox(width: 8),
            // Combo badge — the engagement hook.
            ValueListenableBuilder<int>(
              valueListenable: g.comboNotifier,
              builder: (_, v, __) => v >= 2
                  ? _Pill(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.orange,
                      child: Text(
                        'x$v',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange),
                      ),
                    )
                  : const SizedBox.shrink(),
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
              onPressed: () {
                Sfx.play('click.wav');
                g.togglePause();
              },
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
      const SizedBox(height: 10),
      _MenuButton(
        label: 'Quit to menu',
        icon: Icons.home_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

Widget _gameOver(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  final best = g.isDaily
      ? SaveData.dailyBest(g.dailyKey)
      : SaveData.bestScore(g.level);
  return _OverlayCard(
    title: g.isDaily ? "Daily over!" : 'Game Over',
    subtitle: g.isDaily
        ? 'Come back tomorrow for a new board.'
        : 'The bubbles reached the red line!',
    children: [
      Text(
        'Score: ${g.score}',
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
      ),
      const SizedBox(height: 4),
      Text('Best: $best',
          style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const SizedBox(height: 14),
      _MenuButton(
          label: 'Try again', icon: Icons.refresh_rounded, onTap: g.retryLevel),
      const SizedBox(height: 10),
      _MenuButton(
        label: 'Quit to menu',
        icon: Icons.home_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

Widget _levelComplete(BuildContext context, Game game) {
  final g = game as BubbleShooterGame;
  final best = g.isDaily
      ? SaveData.dailyBest(g.dailyKey)
      : SaveData.bestScore(g.level);
  return _OverlayCard(
    title: g.isDaily ? 'Daily complete!' : 'Level ${g.level} complete!',
    children: [
      if (!g.isDaily)
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
      if (!g.isDaily) const SizedBox(height: 8),
      Text(
        'Score: ${g.score}',
        style: const TextStyle(fontSize: 18, color: Colors.white70),
      ),
      const SizedBox(height: 4),
      Text('Best: $best',
          style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const SizedBox(height: 14),
      if (!g.isDaily)
        _MenuButton(
          label: 'Next level',
          icon: Icons.arrow_forward_rounded,
          onTap: g.nextLevel,
        ),
      if (!g.isDaily) const SizedBox(height: 10),
      _MenuButton(
        label: 'Back to menu',
        icon: Icons.home_rounded,
        onTap: () => Navigator.of(context).pop(),
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
        onPressed: () {
          Sfx.play('click.wav');
          onTap();
        },
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
