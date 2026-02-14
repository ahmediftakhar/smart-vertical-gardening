import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantName;

  const PlantDetailScreen({super.key, required this.plantName});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late DatabaseReference _plantRef;

  double suggestedLight = 0.0;
  double suggestedTemp = 0.0;
  double suggestedWater = 0.0;

  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDatabaseAndFetch();
    });
  }

  Future<void> _initializeDatabaseAndFetch() async {
    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();

      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      _plantRef = database.ref('plants/${widget.plantName}');
      await _fetchPlantDetails();
    } catch (e) {
      debugPrint('❌ Firebase error: $e');
      if (mounted) {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPlantDetails() async {
    try {
      final snapshot = await _plantRef.get();

      if (!mounted || !snapshot.exists) {
        if (mounted) {
          setState(() {
            isError = true;
            isLoading = false;
          });
        }
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      if (mounted) {
        setState(() {
          suggestedLight = _parseDouble(data['suggested_light'], 0.0);
          suggestedTemp = _parseDouble(data['suggested_temp'], 0.0);
          suggestedWater = _parseDouble(data['suggested_water'], 0.0);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching plant details: $e');
      if (mounted) {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    }
  }

  double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Detail'),
        backgroundColor: Colors.green[800],
        leading: const BackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
              ? const Center(
                  child: Text(
                    'Error loading suggested environment.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plantName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Suggested Environment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card-style display of thresholds
                      _buildThresholdTile(
                        icon: Icons.wb_sunny,
                        label: 'Light Intensity',
                        value: '$suggestedLight hrs',
                      ),
                      _buildThresholdTile(
                        icon: Icons.thermostat,
                        label: 'Temperature',
                        value: '$suggestedTemp °C',
                      ),
                      _buildThresholdTile(
                        icon: Icons.water_drop,
                        label: 'Water Level',
                        value: '$suggestedWater %',
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // Do nothing (already here)
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/status');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/automation');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Plant Detail',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
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

  Widget _buildThresholdTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.green[800]),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
