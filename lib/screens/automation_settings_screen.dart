import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AutomationSettingsScreen extends StatefulWidget {
  const AutomationSettingsScreen({super.key});

  @override
  State<AutomationSettingsScreen> createState() =>
      _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends State<AutomationSettingsScreen> {
  late DatabaseReference _dbRef;

  double soil1Threshold = 0.0;
  double soil2Threshold = 0.0;
  double tempThreshold = 0.0;
  double lightThreshold = 0.0;

  final _soil1Controller = TextEditingController();
  final _soil2Controller = TextEditingController();
  final _tempController = TextEditingController();
  final _lightController = TextEditingController();

  bool isUpdating = false;
  bool isLoading = true;

  // VALID RANGES
  static const double soilMinAllowed = 0;
  static const double soilMaxAllowed = 100;
  static const double tempMinAllowed = 0;
  static const double tempMaxAllowed = 100;
  static const double lightMinAllowed = 0;
  static const double lightMaxAllowed = 4095;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();

      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      _dbRef = database.ref('plant_monitor/thresholds');
      _listenToThresholds();
    });
  }

  void _listenToThresholds() {
    _dbRef.onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        soil1Threshold = _parseDouble(data['soil1']);
        soil2Threshold = _parseDouble(data['soil2']);
        tempThreshold = _parseDouble(data['temp']);
        lightThreshold = _parseDouble(data['light']);
        isLoading = false;
      });
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  bool _isValidRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  Future<void> _updateThresholds() async {
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => isUpdating = true);

    final newSoil1 =
        double.tryParse(_soil1Controller.text) ?? soil1Threshold;
    final newSoil2 =
        double.tryParse(_soil2Controller.text) ?? soil2Threshold;
    final newTemp =
        double.tryParse(_tempController.text) ?? tempThreshold;
    final newLight =
        double.tryParse(_lightController.text) ?? lightThreshold;

    if (!_isValidRange(newSoil1, soilMinAllowed, soilMaxAllowed) ||
        !_isValidRange(newSoil2, soilMinAllowed, soilMaxAllowed) ||
        !_isValidRange(newTemp, tempMinAllowed, tempMaxAllowed) ||
        !_isValidRange(newLight, lightMinAllowed, lightMaxAllowed)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('❌ Invalid threshold! Please enter values within range.'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => isUpdating = false);
      return;
    }

    try {
      await _dbRef.update({
        'soil1': newSoil1,
        'soil2': newSoil2,
        'temp': newTemp,
        'light': newLight,
      });

      if (!mounted) return;

      setState(() {
        soil1Threshold = newSoil1;
        soil2Threshold = newSoil2;
        tempThreshold = newTemp;
        lightThreshold = newLight;
      });

      _soil1Controller.clear();
      _soil2Controller.clear();
      _tempController.clear();
      _lightController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Thresholds updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to update thresholds'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;
    setState(() => isUpdating = false);
  }

  Widget _buildThresholdTile({
    required IconData icon,
    required String label,
    required String unit,
    required double currentValue,
    required TextEditingController controller,
    required double min,
    required double max,
  }) {
    final isInvalid = !_isValidRange(currentValue, min, max);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isInvalid ? Colors.red : Colors.green),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Current: $currentValue $unit',
              style:
                  TextStyle(color: isInvalid ? Colors.red : Colors.green[800]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter new ($unit)',
                helperText: 'Allowed range: $min – $max',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _soil1Controller.dispose();
    _soil2Controller.dispose();
    _tempController.dispose();
    _lightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Settings'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildThresholdTile(
                    icon: Icons.water_drop,
                    label: 'Soil 1 Moisture',
                    unit: '%',
                    currentValue: soil1Threshold,
                    controller: _soil1Controller,
                    min: soilMinAllowed,
                    max: soilMaxAllowed,
                  ),
                  _buildThresholdTile(
                    icon: Icons.water_drop_outlined,
                    label: 'Soil 2 Moisture',
                    unit: '%',
                    currentValue: soil2Threshold,
                    controller: _soil2Controller,
                    min: soilMinAllowed,
                    max: soilMaxAllowed,
                  ),
                  _buildThresholdTile(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    unit: '°C',
                    currentValue: tempThreshold,
                    controller: _tempController,
                    min: tempMinAllowed,
                    max: tempMaxAllowed,
                  ),
                  _buildThresholdTile(
                    icon: Icons.wb_sunny,
                    label: 'Light Intensity',
                    unit: 'lx',
                    currentValue: lightThreshold,
                    controller: _lightController,
                    min: lightMinAllowed,
                    max: lightMaxAllowed,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isUpdating ? null : _updateThresholds,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Text(
                        isUpdating ? 'Updating...' : 'Update Thresholds',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
