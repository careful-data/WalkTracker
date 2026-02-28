import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'screens/tracker_screen.dart';
import 'screens/history_screen.dart';

class WalkTrackerLiteApp extends StatelessWidget {
  const WalkTrackerLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WalkTracker Lite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccentColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const TrackerScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
