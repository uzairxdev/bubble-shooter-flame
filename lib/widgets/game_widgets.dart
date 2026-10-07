import 'package:flutter/material.dart';

import '../game/sfx.dart';

/// Small stat pill used in the HUD (score, level, combo).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

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

/// Big rounded button for menus.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 6,
          ),
        ),
      ),
    );
  }
}

/// Card used by all game overlays (pause, game over, level complete).
class OverlayCard extends StatelessWidget {
  const OverlayCard(
      {super.key, required this.title, this.subtitle, required this.children});

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

/// Button inside an overlay card.
class OverlayButton extends StatelessWidget {
  const OverlayButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

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
