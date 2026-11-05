import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  String formatTime(String? isoString) {
    if (isoString == null) return "Unknown";
    final dt = DateTime.parse(isoString).toLocal();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget buildLogCard(Map<String, dynamic> log) {
    final name = log['name'] ?? "Unnamed";
    final emoji = log['emoji'] ?? "🍽️";
    final quantity = log['quantity'] ?? 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text("$name (x$quantity)"),
        subtitle: Text(
          "Time: ${formatTime(log['consumed_at'])} | "
              "Calories: ${log['total_calories'] ?? 0} kcal | "
              "Carbs: ${log['total_carbs'] ?? 0}g, Protein: ${log['total_protein'] ?? 0}g, "
              "Fat: ${log['total_fat'] ?? 0}g, Fiber: ${log['total_fiber'] ?? 0}g",
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildDailySummary(
      double calories, double carbs, double protein, double fat, double fiber) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            Text("Calories: ${calories.toInt()} kcal"),
            Text("Carbs: ${carbs.toInt()} g"),
            Text("Protein: ${protein.toInt()} g"),
            Text("Fat: ${fat.toInt()} g"),
            Text("Fiber: ${fiber.toInt()} g"),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> weeklyCalories,
      DateTime selectedDate) {
    if (weeklyCalories.isEmpty) return const SizedBox.shrink();

    final maxCal = weeklyCalories
        .map((d) => (d['calories'] as double))
        .fold<double>(0, (prev, c) => c > prev ? c : prev);
    final chartMaxY = maxCal < 200 ? 200.0 : maxCal + 50;

    return Card(
      margin: const EdgeInsets.all(12),
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              barGroups: weeklyCalories.asMap().entries.map((entry) {
                final i = entry.key;
                final day = weeklyCalories[i]['day'] as DateTime;
                final calories =
                (weeklyCalories[i]['calories'] as num).toDouble();
                final isSelected = DateFormat('yyyy-MM-dd').format(day) ==
                    DateFormat('yyyy-MM-dd').format(selectedDate);

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: calories,
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                      color: isSelected ? Colors.orange : Colors.blueAccent,
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= weeklyCalories.length)
                        return const SizedBox.shrink();
                      final day = weeklyCalories[value.toInt()]['day'] as DateTime;
                      return Text(
                        DateFormat('E').format(day),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final today = DateTime.now();
    final threeDays = [
      today.subtract(const Duration(days: 2)),
      today.subtract(const Duration(days: 1)),
      today,
    ];

    Widget buildDayChip(DateTime date) {
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;

      return GestureDetector(
        onTap: () => ref.read(historyProvider(date).future),
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('E').format(date),
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(DateFormat('d').format(date),
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...threeDays.map(buildDayChip),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) ref.read(historyProvider(picked).future);
            },
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text("🗓️", style: TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    // Watch the FutureProvider
    final historyAsync = ref.watch(historyProvider(selectedDate));

    return historyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text("History")),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text("History")),
        body: Center(child: Text("Failed to load data: $err")),
      ),
      data: (_) {
        final combinedLogs = ref.watch(combinedLogsProvider);
        final weeklyCalories = ref.watch(weeklyCaloriesProvider);

        final groupedMeals = groupLogsByMeal(combinedLogs);

        double totalCalories = 0, carbs = 0, protein = 0, fat = 0, fiber = 0;
        for (var log in combinedLogs) {
          totalCalories += (log['total_calories'] ?? 0).toDouble();
          carbs += (log['total_carbs'] ?? 0).toDouble();
          protein += (log['total_protein'] ?? 0).toDouble();
          fat += (log['total_fat'] ?? 0).toDouble();
          fiber += (log['total_fiber'] ?? 0).toDouble();
        }

        return Scaffold(
          appBar: AppBar(title: const Text("History")),
          body: Column(
            children: [
              _buildDateSelector(context, ref, selectedDate),
              _buildWeeklyChart(weeklyCalories, selectedDate),
              _buildDailySummary(totalCalories, carbs, protein, fat, fiber),
              Expanded(
                child: combinedLogs.isEmpty
                    ? const Center(child: Text("No logs for this day."))
                    : RefreshIndicator(
                  onRefresh: () => ref.refresh(historyProvider(selectedDate).future),
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: groupedMeals.entries
                        .where((entry) => entry.value.isNotEmpty)
                        .map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        ...entry.value.map(buildLogCard),
                      ],
                    ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
