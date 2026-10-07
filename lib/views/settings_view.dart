import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_viewmodel.dart';

/// Settings: sound, vibration, colorblind palette, reset progress.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
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
      await vm.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress reset.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound effects'),
            secondary: const Icon(Icons.volume_up_rounded),
            value: vm.sound,
            onChanged: vm.setSound,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            secondary: const Icon(Icons.vibration_rounded),
            value: vm.vibration,
            onChanged: vm.setVibration,
          ),
          SwitchListTile(
            title: const Text('Colorblind-friendly palette'),
            subtitle:
                const Text('Swaps bubble colors for an accessible set'),
            secondary: const Icon(Icons.palette_rounded),
            value: vm.colorblind,
            onChanged: vm.setColorblind,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded,
                color: Colors.redAccent),
            title: const Text('Reset all progress',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => _confirmReset(context),
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
