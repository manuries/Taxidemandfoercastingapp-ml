import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api_service.dart';





void main() {
  runApp(const TaxiForecastApp());
}

class TaxiForecastApp extends StatelessWidget {
  const TaxiForecastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Demand Forecasting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LoginScreen(),
    );
  }
}

//////////////////// LOGIN SCREEN ////////////////////
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_taxi, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverScreen()),
                );
              },
              child: const Text("Login as Driver"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManagerScreen()),
                );
              },
              child: const Text("Login as Fleet Manager"),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////// DRIVER SCREEN ////////////////////
//////////////////// DRIVER SCREEN ////////////////////
class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  Map<String, dynamic>? prediction;
  List<dynamic> zoneForecastData = [];
  int selectedHour = 10;
  bool isWeekend = false;

  final List<String> allZones = ["Midtown","Downtown","Uptown","Queens","Brooklyn"];

  // Static weekly scatter plot data
  final staticWeekData = [
    {"day": "Monday", "zone": "Midtown", "trips": 120},
    {"day": "Tuesday", "zone": "Downtown", "trips": 95},
    {"day": "Wednesday", "zone": "Uptown", "trips": 80},
    {"day": "Thursday", "zone": "Queens", "trips": 110},
    {"day": "Friday", "zone": "Brooklyn", "trips": 150},
    {"day": "Saturday", "zone": "Midtown", "trips": 200},
    {"day": "Sunday", "zone": "Downtown", "trips": 170},
  ];

  void _loadPrediction() async {
    final data = await ApiService.predict(selectedHour, isWeekend ? 1 : 0, "driver");
    setState(() => prediction = data);
  }

  void _loadZoneForecast() async {
    final data = await ApiService.zoneForecast(
      24,
      pickupHour: selectedHour,
      isWeekend: isWeekend ? 1 : 0,
    );

    // Normalize zones
    List<dynamic> normalized = allZones.map((zone) {
      var match = data.firstWhere(
              (item) => item['zone'] == zone,
          orElse: () => {"zone": zone, "trips": 0, "earnings": 0.0, "demand": "LOW"}
      );
      return match;
    }).toList();

    setState(() => zoneForecastData = normalized);
  }

  int _mapDemandLevel(String demand) {
    switch (demand) {
      case "LOW": return 1;
      case "MEDIUM": return 2;
      case "HIGH": return 3;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Filters
          DropdownButton<int>(
            value: selectedHour,
            items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("Hour $i"))),
            onChanged: (val) => setState(() => selectedHour = val!),
          ),
          SwitchListTile(
            title: const Text("Weekend?"),
            value: isWeekend,
            onChanged: (val) => setState(() => isWeekend = val),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _loadPrediction, child: const Text("Get Prediction")),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _loadZoneForecast, child: const Text("Load Zone Forecast")),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 Prediction Card
          if (prediction != null)
            Card(
              child: ListTile(
                title: Text("Demand: ${prediction!['demand']}"),
                subtitle: Text("Trips: ${prediction!['trips']} | Earnings: \$${prediction!['earnings']}"),
                trailing: Text(prediction!['alerts']),
              ),
            ),

          const SizedBox(height: 20),

          // 🔹 Chart 1: Hourly Demand (Zones vs Demand Level)
          // 🔹 Chart 1: Trips per Zone (Bar Chart)
          if (zoneForecastData.isNotEmpty) ...[
            const Text("Trips per Zone", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text("Trips"),
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text("Zones"),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < zoneForecastData.length) {
                            return Transform.rotate(
                              angle: -0.8,
                              child: Text(
                                zoneForecastData[index]['zone'].toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  barGroups: zoneForecastData.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (item['trips'] as num).toDouble(),
                          color: Colors.blue,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],


          // 🔹 Chart 2: Forecasted Demand (Zones vs Trips)
          if (zoneForecastData.isNotEmpty) ...[
            const Text("Forecasted Demand (Next 24h)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text("Trips"),
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text("Zones"),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < zoneForecastData.length) {
                            return Transform.rotate(
                              angle: -0.8,
                              child: Text(zoneForecastData[index]['zone'].toString(),
                                  style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: zoneForecastData.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        return FlSpot(index.toDouble(), (item['trips'] as num).toDouble());
                      }).toList(),
                      isCurved: true,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 🔹 Chart 3: Static Scatter Plot (Weekly Highest Demand Zones)
          const Text("Static Scatter Plot: Weekly Highest Demand Zones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 250,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: staticWeekData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return ScatterSpot(
                    index.toDouble(),
                    (item['trips'] as int).toDouble(),
                    dotPainter: FlDotCirclePainter(
                      radius: 6,
                      color: Colors.purple,
                    ),
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Trips"),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Days"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < staticWeekData.length) {
                          return Text(
                            staticWeekData[index]['day'].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//////////////////// MANAGER SCREEN ////////////////////
//////////////////// MANAGER SCREEN ////////////////////
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  List<dynamic> zoneForecastData = [];
  int selectedHour = 10;
  bool isWeekend = false;
  int totalTrips = 0;
  double totalEarnings = 0.0;

  final List<String> allZones = ["Midtown","Downtown","Uptown","Queens","Brooklyn"];

  // ✅ Static demo data for weekly scatter plot
  final staticWeekData = [
    {"day": "Monday", "zone": "Midtown", "trips": 120},
    {"day": "Tuesday", "zone": "Downtown", "trips": 95},
    {"day": "Wednesday", "zone": "Uptown", "trips": 80},
    {"day": "Thursday", "zone": "Queens", "trips": 110},
    {"day": "Friday", "zone": "Brooklyn", "trips": 150},
    {"day": "Saturday", "zone": "Midtown", "trips": 200},
    {"day": "Sunday", "zone": "Downtown", "trips": 170},
  ];

  void _loadFilteredData() async {
    final data = await ApiService.zoneForecast(
      24,
      pickupHour: selectedHour,
      isWeekend: isWeekend ? 1 : 0,
    );

    // ✅ Normalize zones
    List<dynamic> normalized = allZones.map((zone) {
      var match = data.firstWhere(
              (item) => item['zone'] == zone,
          orElse: () => {"zone": zone, "trips": 0, "earnings": 0.0, "demand": "LOW"}
      );
      return match;
    }).toList();

    int tripsSum = normalized.fold(0, (sum, item) => sum + (item['trips'] as int));
    double earningsSum = normalized.fold(0.0, (sum, item) => sum + (item['earnings'] as num).toDouble());

    setState(() {
      zoneForecastData = normalized;
      totalTrips = tripsSum;
      totalEarnings = earningsSum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fleet Manager Dashboard")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Filter section
          DropdownButton<int>(
            value: selectedHour,
            items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text("Hour $i"))),
            onChanged: (val) => setState(() => selectedHour = val!),
          ),
          SwitchListTile(
            title: const Text("Weekend?"),
            value: isWeekend,
            onChanged: (val) => setState(() => isWeekend = val),
          ),
          ElevatedButton(
            onPressed: _loadFilteredData,
            child: const Text("Filter Forecast"),
          ),

          const SizedBox(height: 20),

          // 🔹 Summary Cards
          Card(
            child: ListTile(
              title: const Text("Total Trips"),
              subtitle: Text("$totalTrips trips"),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text("Total Earnings"),
              subtitle: Text("\$${totalEarnings.toStringAsFixed(2)}"),
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Chart 1: Heatmap of Trips per Zone
          const Text("Heatmap: Trips per Zone", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Trips"),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Zones"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < zoneForecastData.length) {
                          return Transform.rotate(
                            angle: -0.8,
                            child: Text(
                              zoneForecastData[index]['zone'].toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                ),
                barGroups: zoneForecastData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (item['trips'] as int).toDouble(),
                        color: item['demand'].toString() == "HIGH"
                            ? Colors.red
                            : item['demand'].toString() == "MEDIUM"
                            ? Colors.orange
                            : Colors.green,
                        width: 16,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Chart 2: Scatter Line Chart of Earnings
          const Text("Scatter Line Chart: Earnings per Zone", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Earnings"),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Zones"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < zoneForecastData.length) {
                          return Transform.rotate(
                            angle: -0.8,
                            child: Text(
                              zoneForecastData[index]['zone'].toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: zoneForecastData.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      return FlSpot(
                        index.toDouble(),
                        (item['earnings'] as num).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Chart 3: Static Scatter Plot (Weekly Highest Demand Zones)
          const Text("Static Scatter Plot: Weekly Highest Demand Zones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 250,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: staticWeekData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return ScatterSpot(
                    index.toDouble(),
                    (item['trips'] as int).toDouble(),
                    dotPainter: FlDotCirclePainter(
                      radius: 6,
                      color: Colors.purple,
                    ),
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("Trips"),
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Days"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < staticWeekData.length) {
                          return Text(
                            staticWeekData[index]['day'].toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text("");
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



