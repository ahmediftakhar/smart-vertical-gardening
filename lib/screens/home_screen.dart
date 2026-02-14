// lib/screens/home_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/feedback_dialog.dart';

class SavedPlant {
  String? id; // Firebase key
  final String category;
  final String plant;

  SavedPlant({this.id, required this.category, required this.plant});

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'plant': plant,
      };

  static SavedPlant fromJson(Map<dynamic, dynamic> json) {
    return SavedPlant(
      id: json['id']?.toString(),
      category: json['category']?.toString() ?? '',
      plant: json['plant']?.toString() ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();

  late DatabaseReference _categoryRef;
  late DatabaseReference _userRef;

  List<String> allCategories = [];
  List<String> filteredCategories = [];
  String? selectedCategory;

  bool isLoading = true;

  List<SavedPlant> savedPlants = [];

  String? macAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadData();
      _startFeedbackTimer();
    });
    searchController.addListener(_filterCategories);
  }

  Future<void> _initializeAndLoadData() async {
    try {
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();

      final db = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      _categoryRef = db.ref('plant_categories');
      _userRef = db.ref('users');

      final prefs = await SharedPreferences.getInstance();
      macAddress = prefs.getString('mac_address');

      final categorySnapshot = await _categoryRef.get();
      List<String> categories = [];
      if (categorySnapshot.exists && categorySnapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(categorySnapshot.value as Map);
          categories = data.keys.map((e) => e.toString()).toList();
        } catch (_) {}
      }

      List<SavedPlant> loadedPlants = [];

      if (macAddress != null && macAddress!.isNotEmpty) {
        final plantsSnap =
            await _userRef.child('$macAddress/saved_plants').get();
        if (plantsSnap.exists && plantsSnap.value != null) {
          try {
            final Map<dynamic, dynamic> raw =
                Map<dynamic, dynamic>.from(plantsSnap.value as Map);
            raw.forEach((key, value) {
              try {
                final map = Map<String, dynamic>.from(value as Map);
                map['id'] = key;
                loadedPlants.add(SavedPlant.fromJson(map));
              } catch (_) {}
            });

            await prefs.setString(
              'saved_plants_cache',
              jsonEncode(loadedPlants.map((p) => p.toJson()).toList()),
            );
          } catch (_) {}
        }
      }

      if (loadedPlants.isEmpty) {
        final localJson = prefs.getString('saved_plants_cache');
        if (localJson != null) {
          try {
            final list = jsonDecode(localJson) as List<dynamic>;
            loadedPlants = list
                .map((e) => SavedPlant.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        allCategories = categories;
        filteredCategories = categories;
        savedPlants = loadedPlants;
        isLoading = false;
      });
    } catch (e, st) {
      debugPrint("❌ Error initializing home screen: $e\n$st");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterCategories() {
    final query = searchController.text.trim().toLowerCase();
    final filtered = allCategories
        .where((cat) => cat.toLowerCase().startsWith(query))
        .toList();
    if (!mounted) return;
    setState(() {
      filteredCategories = filtered;
    });
  }

  void _onCategorySelected(String? category) {
    if (category == null || !mounted) return;

    Navigator.pushNamed(context, '/plants', arguments: category)
        .then((selectedPlantName) async {
      if (selectedPlantName != null && selectedPlantName is String) {
        await _addSavedPlant(category, selectedPlantName);
      }
    });
  }

  Future<void> _addSavedPlant(String category, String plant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mac = macAddress;

      final newPlant = SavedPlant(category: category, plant: plant);

      if (mac != null && mac.isNotEmpty) {
        final ref = _userRef.child('$mac/saved_plants').push();
        await ref.set({'category': category, 'plant': plant});
        newPlant.id = ref.key;
      }

      final updated = List<SavedPlant>.from(savedPlants)..insert(0, newPlant);

      await prefs.setString(
        'saved_plants_cache',
        jsonEncode(updated.map((p) => p.toJson()).toList()),
      );

      if (!mounted) return;
      setState(() {
        savedPlants = updated;
      });

      Navigator.pushNamed(context, '/pros-cons', arguments: plant);
    } catch (e) {
      debugPrint('❌ Error adding saved plant: $e');
    }
  }

  Future<void> _deleteSavedPlant(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mac = macAddress;
      final plant = savedPlants[index];

      if (mac != null && mac.isNotEmpty && plant.id != null) {
        await _userRef.child('$mac/saved_plants/${plant.id}').remove();
      }

      final updated = List<SavedPlant>.from(savedPlants)..removeAt(index);

      await prefs.setString(
        'saved_plants_cache',
        jsonEncode(updated.map((p) => p.toJson()).toList()),
      );

      if (!mounted) return;
      setState(() {
        savedPlants = updated;
      });
    } catch (e) {
      debugPrint('❌ Error deleting saved plant: $e');
    }
  }

  void _navigateToSavedPlant(SavedPlant p) {
    Navigator.pushNamed(context, '/pros-cons', arguments: p.plant);
  }

  void _startFeedbackTimer() {
    Future.delayed(const Duration(minutes: 3), () {
      if (!mounted) return;
      FeedbackDialog.show(context);
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterCategories);
    searchController.dispose();
    super.dispose();
  }

  Widget _buildSavedPlantsList() {
    if (savedPlants.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No saved plants yet.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showCategoryPickerDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add a plant'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < savedPlants.length; i++)
          Card(
            color: Colors.green[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.local_florist, color: Colors.green),
              title: Text(savedPlants[i].plant,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Category: ${savedPlants[i].category}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.green),
                    onPressed: () => _navigateToSavedPlant(savedPlants[i]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmAndDelete(i),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _confirmAndDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove saved plant?'),
        content: Text(
            'Are you sure you want to remove "${savedPlants[index].plant}" from saved plants?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSavedPlant(index);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCategoryPickerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: filteredCategories.map((cat) {
              return ListTile(
                title: Text(cat),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/plants', arguments: cat)
                      .then((selectedPlantName) async {
                    if (selectedPlantName != null &&
                        selectedPlantName is String) {
                      await _addSavedPlant(cat, selectedPlantName);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[800],
          title: const Text('Home', style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCategoryPickerDialog,
          backgroundColor: Colors.green[800],
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: SingleChildScrollView( // ✅ SCROLL ADDED HERE
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Plants',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSavedPlantsList(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search category...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Select the category of your plant',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Choose a category'),
                    items: filteredCategories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (cat) {
                      if (cat == null) return;
                      selectedCategory = cat;
                      _onCategorySelected(cat);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
