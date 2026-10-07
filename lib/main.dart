import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'game/save_data.dart';
import 'viewmodels/menu_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/menu_view.dart';

/// App bootstrap: initializes persistence, then provides the app-wide
/// viewmodels (MVVM) above the view tree.
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bubble Pop!',
        theme: ThemeData.dark(useMaterial3: true),
        home: const MenuView(),
      ),
    );
  }
}
