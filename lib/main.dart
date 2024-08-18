import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

// The entry point of the app
void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}

// GoRouter configuration
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/chart',
      builder: (context, state) => RainfallChartScreen(),
    ),
  ],
);

// A provider to fetch and manage API data using Riverpod
final rainfallDataProvider = FutureProvider<List<RainfallData>>((ref) async {
  final response = await http.get(
    Uri.parse(
        'https://api.data.gov.in/resource/c9302010-023d-4c91-863e-3177079c0410?api-key=579b464db66ec23bdd00000178625ad5b9f946585554cb0d2067addc&format=json&offset=0&limit=10'),
  );

  if (response.statusCode == 200) {
    print(response.body);  // Check the API response in the console
    final data = jsonDecode(response.body)['records'] as List;
    return data.map((item) => RainfallData.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load rainfall data');
  }
});

// The Home screen with a button to navigate to the chart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/chart');
          },
          child: Text('View Rainfall Chart'),
        ),
      ),
    );
  }
}

// The screen that displays the rainfall chart
class RainfallChartScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(rainfallDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Rainfall Chart')),
      body: data.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (rainfallData) {
          if (rainfallData.isEmpty) {
            return Center(child: Text('No data available to display.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= rainfallData.length) {
                          return Container(); // Return empty widget if index is out of bounds
                        }
                        return Text(rainfallData[value.toInt()].month);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toString());
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: rainfallData
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.rainfall.toDouble()))
                        .toList(),
                    isCurved: true,
                    barWidth: 2,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// A model to represent the rainfall data
class RainfallData {
  final String month;
  final double rainfall;

  RainfallData({required this.month, required this.rainfall});

  factory RainfallData.fromJson(Map<String, dynamic> json) {
    return RainfallData(
      // Use a default value or handle null gracefully
      month: json['month'] != null ? json['month'] as String : 'Unknown',
      // Parse the rainfall value or default to 0.0 if null
      rainfall: json['rainfall'] != null ? double.tryParse(json['rainfall'] as String) ?? 0.0 : 0.0,
    );
  }
}

