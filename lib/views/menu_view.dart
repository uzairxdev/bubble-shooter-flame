import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/menu_viewmodel.dart';
import '../widgets/game_widgets.dart';
import 'game_view.dart';
import 'level_select_view.dart';
import 'settings_view.dart';
import '../viewmodels/game_session_viewmodel.dart';

/// Main menu: Play, Daily Challenge, Settings + lifetime stats.
class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuViewModel>();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          Container(color: Colors.black45),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Scales gracefully from small phones to tablets.
                final h = constraints.maxHeight;
                return Column(
                  children: [
                    SizedBox(height: h * 0.04),
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
                    SizedBox(height: h * 0.01),
                    // Poppy, the mascot (transparent PNG).
                    Image.asset('assets/images/mascot.png',
                        height: h * 0.24),
                    const Spacer(),
                    MenuButton(
                      label: 'Play',
                      icon: Icons.play_arrow_rounded,
                      color: const Color(0xFF4D9FFF),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) => const LevelSelectView()))
                          .then((_) => vm.refresh()),
                    ),
                    const SizedBox(height: 12),
                    MenuButton(
                      label: vm.dailyBest > 0
                          ? 'Daily Challenge  •  best ${vm.dailyBest}'
                          : 'Daily Challenge',
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFFB366FF),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) => const GameView(
                                  level: 1, mode: GameMode.daily)))
                          .then((_) => vm.refresh()),
                    ),
                    const SizedBox(height: 12),
                    MenuButton(
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      color: const Color(0xFF5A6B8C),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsView())),
                    ),
                    const Spacer(),
                    Text(
                      '🔥 Best combo x${vm.bestCombo}    •    🏆 ${vm.totalWins} wins',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: h * 0.025),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
