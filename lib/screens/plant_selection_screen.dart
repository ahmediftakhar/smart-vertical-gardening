// lib/screens/plant_selection_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlantSelectionScreen extends StatefulWidget {
  final String category;

  const PlantSelectionScreen({super.key, required this.category});

  @override
  State<PlantSelectionScreen> createState() => _PlantSelectionScreenState();
}

class _PlantSelectionScreenState extends State<PlantSelectionScreen> {
  final TextEditingController searchController = TextEditingController();

  late FirebaseDatabase database;
  late DatabaseReference _plantRef;   // <-- Only this needed

  List<String> plantList = [];
  List<String> filteredList = [];
  String? selectedPlant; // SINGLE selection
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDatabaseAndFetch();
    });
    searchController.addListener(_filterPlants);
  }

  Future<void> _initializeDatabaseAndFetch() async {
    try {
      final app = Firebase.apps.isEmpty ? await Firebase.initializeApp() : Firebase.app();

      database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      _plantRef = database.ref('plant_categories/${widget.category}');

      // Load previously saved selected plant for this category (optional)
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_plants_cache_${widget.category}');
      if (savedJson != null) {
        try {
          final decoded = jsonDecode(savedJson);
          if (decoded is List && decoded.isNotEmpty) {
            selectedPlant = decoded.first.toString();
          }
        } catch (_) {}
      }

      await _fetchPlants();
    } catch (e, st) {
      debugPrint("❌ Firebase error: $e\n$st");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPlants() async {
    try {
      final snapshot = await _plantRef.get();
      if (!mounted) return;

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value!;
        final List<String> plants = [];

        if (value is Map) {
          for (final k in value.keys) {
            plants.add(k.toString());
          }
        } else if (value is List) {
          for (final v in value) {
            plants.add(v.toString());
          }
        } else {
          plants.add(value.toString());
        }

        setState(() {
          plantList = plants;
          filteredList = List.from(plants);
          isLoading = false;
        });
      } else {
        setState(() {
          plantList = [];
          filteredList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching plants: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterPlants() {
    final query = searchController.text.trim().toLowerCase();
    final updated =
        plantList.where((plant) => plant.toLowerCase().contains(query)).toList();
    if (!mounted) return;
    setState(() {
      filteredList = updated;
    });
  }

  /// Save selection locally (category-level cache) — optional convenience
  Future<void> _saveLocalCache(String category, String plant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'saved_plants_cache_$category';

      List<String> list = [];
      final raw = prefs.getString(key);

      if (raw != null) {
        try {
          final dec = jsonDecode(raw) as List<dynamic>;
          list = dec.map((e) => e.toString()).toList();
        } catch (_) {
          list = [];
        }
      }

      if (!list.contains(plant)) {
        list.insert(0, plant);
      }

      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint("❌ Error caching local plant selection: $e");
    }
  }

  void _onContinue() async {
    if (selectedPlant == null || selectedPlant!.isEmpty) return;

    await _saveLocalCache(widget.category, selectedPlant!);

    if (!mounted) return;

    Navigator.pop(context, selectedPlant);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterPlants);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category: ${widget.category}'),
        backgroundColor: Colors.green[800],
        leading: const BackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SEARCH BAR
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a plant...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                _filterPlants();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Select a plant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('No plants found for this category.'))
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final plant = filteredList[index];
                              final checked = selectedPlant == plant;

                              return ListTile(
                                title: Text(plant),
                                trailing: checked
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    selectedPlant = plant;
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Continue',
                        style:
                            TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      onPressed:
                          (selectedPlant == null) ? null : _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
