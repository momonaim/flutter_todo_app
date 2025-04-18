import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      // For desktop, use sqflite_common_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    WidgetsFlutterBinding.ensureInitialized();

    if (defaultTargetPlatform == TargetPlatform.windows) {
      // Initialize window_manager
      await windowManager.ensureInitialized();

      // Set custom window size
      await windowManager.setSize(const Size(800, 600));

      // Optionally, you can set a minimum and maximum size
      await windowManager.setMinimumSize(const Size(400, 450));
      await windowManager.setMaximumSize(const Size(1600, 900));
    }

    // Initialiser les timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    runApp(const MyApp());
  } catch (e) {
    if (kDebugMode) {
      print("Error initializing app: $e");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '📝 Daily To-Do',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[200], // Couleur du fond de l'écran
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black), // Texte par défaut
          bodyMedium: TextStyle(color: Colors.black),
          titleLarge: TextStyle(color: Colors.black, fontSize: 20), // Titre
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.green, // Couleur des boutons
          textTheme: ButtonTextTheme.primary, // Couleur du texte des boutons
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor:
              MaterialStateProperty.all(Colors.white), // Couleur de la coche
          fillColor: MaterialStateProperty.all(
              Colors.green), // Couleur du fond de la case
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
            .copyWith(secondary: Colors.greenAccent),
        // Plus de personnalisations possibles (ex. couleurs des Cards, etc.)
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
