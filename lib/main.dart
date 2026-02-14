import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// Notification service
import 'services/notification_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/mac_registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plant_selection_screen.dart';
import 'screens/pros_cons.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/current_status_screen.dart';
import 'screens/automation_settings_screen.dart';
import 'screens/feedback_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseSafely();

  // 🔔 Initialize notifications (ONLY here)
  await NotificationService.init();

  // 🔁 START GLOBAL SENSOR LISTENER (NEW & REQUIRED)
  _startGlobalSensorListener();

  runApp(const SmartVerticalGardeningApp());
}

Future<void> _initializeFirebaseSafely() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBWEYGqvFFGvQjOR4Awzu_bQ-vr_pJfU54",
          appId: "1:28895873887:android:e626492ccff7647d0f84ea",
          messagingSenderId: "28895873887",
          projectId: "smart-vertical-gardening",
          databaseURL:
              "https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app",
          storageBucket: "smart-vertical-gardening.appspot.com",
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
}

/// 🔁 GLOBAL SENSOR LISTENER (APP-WIDE)
void _startGlobalSensorListener() {
  final db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  final ref = db.ref('plant_monitor/readings');

  // Alert flags (prevent spam)
  bool tempAlert = false;
  bool lightAlert = false;
  bool humidityAlert = false;
  bool soilAlert = false;

  // Thresholds (same as automation/current status)
  const double tempMin = 18;
  const double lightMin = 300;
  const double humidityMin = 30;
  const double soilMin = 20;

  ref.onValue.listen((event) {
    if (event.snapshot.value == null) return;

    final data =
        Map<String, dynamic>.from(event.snapshot.value as Map<dynamic, dynamic>);

    final double temp = _parseDouble(data['temp']);
    final double light = _parseDouble(data['light']);
    final double humidity = _parseDouble(data['humidity']);
    final double soil = _parseDouble(data['soil1']);

    // 🌡 Temperature
    if (temp < tempMin && !tempAlert) {
      NotificationService.show(
        title: 'Temperature Alert',
        body: 'Temperature is below threshold ($temp °C)',
      );
      tempAlert = true;
    }
    if (temp >= tempMin) tempAlert = false;

    // 💡 Light
    if (light < lightMin && !lightAlert) {
      NotificationService.show(
        title: 'Light Alert',
        body: 'Light intensity is below threshold ($light lx)',
      );
      lightAlert = true;
    }
    if (light >= lightMin) lightAlert = false;

    // 💧 Humidity
    if (humidity < humidityMin && !humidityAlert) {
      NotificationService.show(
        title: 'Humidity Alert',
        body: 'Humidity is below threshold ($humidity %)',
      );
      humidityAlert = true;
    }
    if (humidity >= humidityMin) humidityAlert = false;

    // 🌱 Soil
    if (soil < soilMin && !soilAlert) {
      NotificationService.show(
        title: 'Soil Moisture Alert',
        body: 'Soil moisture is below threshold ($soil %)',
      );
      soilAlert = true;
    }
    if (soil >= soilMin) soilAlert = false;
  });
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class SmartVerticalGardeningApp extends StatelessWidget {
  const SmartVerticalGardeningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Vertical Gardening',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/register': (_) => const MacRegistrationScreen(),
        '/home': (_) => const HomeScreen(),
        '/status': (_) => const CurrentStatusScreen(),
        '/automation': (_) => const AutomationSettingsScreen(),
        '/feedback': (_) => const FeedbackScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/plants':
            if (args is String) {
              return MaterialPageRoute(
                builder: (_) => PlantSelectionScreen(category: args),
              );
            }
            break;

          case '/pros-cons':
            if (args is String) {
              return MaterialPageRoute(
                builder: (_) => ProsConsScreen(plantName: args),
              );
            }
            break;

          case '/plant-details':
            if (args is String) {
              return MaterialPageRoute(
                builder: (_) => PlantDetailScreen(plantName: args),
              );
            }
            break;
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('No route defined')),
          ),
        );
      },
    );
  }
}
