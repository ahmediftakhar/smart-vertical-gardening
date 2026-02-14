import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class ProsConsScreen extends StatefulWidget {
  final String plantName;

  const ProsConsScreen({super.key, required this.plantName});

  @override
  State<ProsConsScreen> createState() => _ProsConsScreenState();
}

class _ProsConsScreenState extends State<ProsConsScreen> {
  String? imageUrl;
  List<String> prosList = [];
  List<String> consList = [];
  bool isLoading = true;

  late final DatabaseReference _plantRef;

  @override
  void initState() {
    super.initState();

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://smart-vertical-gardening-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    _plantRef = database.ref('plants/${widget.plantName}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlantData();
    });
  }

  Future<void> _fetchPlantData() async {
    try {
      final snapshot = await _plantRef.get();
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          imageUrl = data['image'] as String?;
          prosList = _parseList(data['pros']);
          consList = _parseList(data['cons']);
          isLoading = false;
        });
      } else {
        setState(() {
          prosList = ['No data found for this plant.'];
          consList = ['No data found for this plant.'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching plant data: $e");
      if (!mounted) return;
      setState(() {
        prosList = ['Error loading data.'];
        consList = ['Error loading data.'];
        isLoading = false;
      });
    }
  }

  List<String> _parseList(dynamic value) {
    if (value is String) {
      return value
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return ['No data available.'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantName),
        backgroundColor: Colors.green[800],
        leading: const BackButton(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Column(
                          children: [
                            Icon(Icons.broken_image,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Image not available'),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "No image available for this plant.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Advantages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...prosList.map((pro) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text("• $pro",
                            style: const TextStyle(fontSize: 16)),
                      )),
                  const SizedBox(height: 24),
                  const Text(
                    'Disadvantages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...consList.map((con) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text("• $con",
                            style: const TextStyle(fontSize: 16)),
                      )),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // any valid index to avoid assertion error
        selectedItemColor: Colors.grey, // all icons same color
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/plant-details',
                  arguments: widget.plantName);
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
}
