import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class CurrentStatusScreen extends StatefulWidget {
  const CurrentStatusScreen({super.key});

  @override
  State<CurrentStatusScreen> createState() => _CurrentStatusScreenState();
}

class _CurrentStatusScreenState extends State<CurrentStatusScreen> {
  late DatabaseReference dbRef;
  Stream<DatabaseEvent>? _sensorStream;

  double currentLight = 0;
  double currentTemp = 0;
  double currentHumidity = 0;
  double currentSoil1 = 0;
  double currentSoil2 = 0;
  String lastUpdated = "—";

  // Threshold ranges
  final double lightMin = 300;
  final double lightMax = 800;
  final double tempMin = 18;
  final double tempMax = 30;
  final double humidityMin = 30;
  final double humidityMax = 80;
  final double soilMin = 20;
  final double soilMax = 80;

  // 🔔 Notification flags
  bool lightAlertSent = false;
  bool tempAlertSent = false;
  bool humidityAlertSent = false;
  bool soil1AlertSent = false;
  bool soil2AlertSent = false;

  final int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebaseAndStartListening();
    });
  }

  Future<void> _initializeFirebaseAndStartListening() async {
    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();

      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      dbRef = database.ref('plant_monitor/readings');
      _sensorStream = dbRef.onValue;

      _sensorStream?.listen((DatabaseEvent event) {
        if (event.snapshot.value != null && mounted) {
          final data = Map<String, dynamic>.from(
              event.snapshot.value as Map<dynamic, dynamic>);

          setState(() {
            currentLight = _parseDouble(data['light']);
            currentTemp = _parseDouble(data['temp']);
            currentHumidity = _parseDouble(data['humidity']);
            currentSoil1 = _parseDouble(data['soil1']);
            currentSoil2 = _parseDouble(data['soil2']);
            lastUpdated = _formatTimestamp(data['timestamp']);
          });

          _checkAndTriggerNotifications();
        }
      });
    } catch (e) {
      debugPrint('❌ Firebase init or stream error: $e');
    }
  }

  void _checkAndTriggerNotifications() {
    // 🌡 Temperature
    if ((currentTemp < tempMin || currentTemp > tempMax) && !tempAlertSent) {
      NotificationService.show(
        title: 'Temperature Alert',
        body: 'Temperature is out of range: ${currentTemp.toStringAsFixed(1)} °C',
      );
      tempAlertSent = true;
    }
    if (currentTemp >= tempMin && currentTemp <= tempMax) {
      tempAlertSent = false;
    }

    // 💡 Light
    if ((currentLight < lightMin || currentLight > lightMax) && !lightAlertSent) {
      NotificationService.show(
        title: 'Light Alert',
        body:
            'Light intensity is out of range: ${currentLight.toStringAsFixed(0)} lx',
      );
      lightAlertSent = true;
    }
    if (currentLight >= lightMin && currentLight <= lightMax) {
      lightAlertSent = false;
    }

    // 💦 Humidity
    if ((currentHumidity < humidityMin || currentHumidity > humidityMax) &&
        !humidityAlertSent) {
      NotificationService.show(
        title: 'Humidity Alert',
        body:
            'Humidity level is out of range: ${currentHumidity.toStringAsFixed(1)}%',
      );
      humidityAlertSent = true;
    }
    if (currentHumidity >= humidityMin &&
        currentHumidity <= humidityMax) {
      humidityAlertSent = false;
    }

    // 🌱 Soil Tray 1
    if ((currentSoil1 < soilMin || currentSoil1 > soilMax) &&
        !soil1AlertSent) {
      NotificationService.show(
        title: 'Soil Moisture Alert (Tray 1)',
        body:
            'Soil moisture is out of range: ${currentSoil1.toStringAsFixed(1)}%',
      );
      soil1AlertSent = true;
    }
    if (currentSoil1 >= soilMin && currentSoil1 <= soilMax) {
      soil1AlertSent = false;
    }

    // 🌱 Soil Tray 2
    if ((currentSoil2 < soilMin || currentSoil2 > soilMax) &&
        !soil2AlertSent) {
      NotificationService.show(
        title: 'Soil Moisture Alert (Tray 2)',
        body:
            'Soil moisture is out of range: ${currentSoil2.toStringAsFixed(1)}%',
      );
      soil2AlertSent = true;
    }
    if (currentSoil2 >= soilMin && currentSoil2 <= soilMax) {
      soil2AlertSent = false;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatTimestamp(dynamic value) {
    if (value == null || value.toString().isEmpty) return "—";
    try {
      DateTime dt = DateTime.parse(value.toString());
      return DateFormat('dd MMM yyyy – hh:mm a').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
  }) {
    final isOutOfRange = value < min || value > max;
    final Color bgColor = isOutOfRange ? Colors.red : Colors.green[800]!;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, size: 40, color: bgColor),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$value $unit',
          style: TextStyle(
            color: bgColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Icon(
          isOutOfRange ? Icons.warning : Icons.check_circle,
          color: isOutOfRange ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/automation');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Status'),
        backgroundColor: Colors.green[800],
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: currentTemp,
              min: tempMin,
              max: tempMax,
              unit: '°C',
            ),
            _buildStatusCard(
              icon: Icons.water_drop,
              label: 'Humidity',
              value: currentHumidity,
              min: humidityMin,
              max: humidityMax,
              unit: '%',
            ),
            _buildStatusCard(
              icon: Icons.wb_sunny,
              label: 'Light Intensity',
              value: currentLight,
              min: lightMin,
              max: lightMax,
              unit: 'lx',
            ),
            _buildStatusCard(
              icon: Icons.grass,
              label: 'Soil Moisture (Tray 1)',
              value: currentSoil1,
              min: soilMin,
              max: soilMax,
              unit: '%',
            ),
            _buildStatusCard(
              icon: Icons.grass_outlined,
              label: 'Soil Moisture (Tray 2)',
              value: currentSoil2,
              min: soilMin,
              max: soilMax,
              unit: '%',
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Last Updated: $lastUpdated",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Current Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Automation',
          ),
        ],
      ),
    );
  }
}
