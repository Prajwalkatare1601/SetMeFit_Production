import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_provider.dart';

class CustomMealPage extends ConsumerStatefulWidget {
  const CustomMealPage({super.key});

  @override
  ConsumerState<CustomMealPage> createState() => _CustomMealPageState();
}

class _CustomMealPageState extends ConsumerState<CustomMealPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emojiController = TextEditingController();
  Map<String, int> selectedFoods = {}; // foodId -> quantity
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(foodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Custom Meal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Meal name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Meal Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Optional emoji
            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: "Emoji (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              decoration: const InputDecoration(
                labelText: "Search foods...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: foodsAsync.when(
                data: (foods) {
                  final filtered = foods.where((f) {
                    return f['name'].toString().toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) return const Center(child: Text("No foods found"));

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final food = filtered[index];
                      final qty = selectedFoods[food['id']] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Text(food['emoji'] ?? "🍴", style: const TextStyle(fontSize: 28)),
                          title: Text(food['name']),
                          subtitle: qty > 0 ? Text("Quantity: $qty") : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (qty > 0) setState(() => selectedFoods[food['id']] = qty - 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() => selectedFoods[food['id']] = qty + 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedFoods.isEmpty || _nameController.text.isEmpty
                    ? null
                    : () async {
                  final items = selectedFoods.entries
                      .where((e) => e.value > 0)
                      .map((e) => {'id': e.key, 'quantity': e.value})
                      .toList();

                  final saveMeal = ref.read(saveCustomMealProvider);
                  await saveMeal(
                    _nameController.text,
                    _emojiController.text.isEmpty ? null : _emojiController.text,
                    items,
                  );

                  Navigator.pop(context, true); // Return true to indicate a new meal was added
                },
                child: const Text("Save Meal"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
