import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Météo Open-Meteo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WeatherHomePage(title: 'Météo Open-Meteo'),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key, required this.title});
  final String title;
  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _weatherData;
  bool _loading = false;
  String? _error;

  Future<void> _fetchWeather() async {
    setState(() {
      _loading = true;
      _error = null;
      _weatherData = null;
    });
    final lat = _latController.text;
    final lon = _lonController.text;
    final start = _startDate?.toIso8601String().split('T').first;
    final end = _endDate?.toIso8601String().split('T').first;
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&start_date=$start&end_date=$end&hourly=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloudcover,windspeed_10m';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la récupération des données.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau : $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Entrez la latitude' : null,
              ),
              TextFormField(
                controller: _lonController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Entrez la longitude' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: Text(_startDate == null ? 'Date de début' : _startDate!.toString().split(' ')[0]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 7)),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      child: Text(_endDate == null ? 'Date de fin' : _endDate!.toString().split(' ')[0]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
                          _fetchWeather();
                        }
                      },
                child: _loading ? const CircularProgressIndicator() : const Text('Obtenir la météo'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_weatherData != null) ...[
                const SizedBox(height: 24),
                const Text('Données météo :', style: TextStyle(fontWeight: FontWeight.bold)),
                WeatherDataTable(weatherData: _weatherData!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherDataTable extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  const WeatherDataTable({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final hourly = weatherData['hourly'] ?? {};
    final times = (hourly['time'] as List?) ?? [];
    final temp = (hourly['temperature_2m'] as List?) ?? [];
    final appTemp = (hourly['apparent_temperature'] as List?) ?? [];
    final humidity = (hourly['relative_humidity_2m'] as List?) ?? [];
    final wind = (hourly['windspeed_10m'] as List?) ?? [];
    final precip = (hourly['precipitation'] as List?) ?? [];
    final cloud = (hourly['cloudcover'] as List?) ?? [];
    return times.isEmpty
        ? const Text('Aucune donnée disponible.')
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Heure')),
                DataColumn(label: Text('Temp. (°C)')),
                DataColumn(label: Text('Ressentie (°C)')),
                DataColumn(label: Text('Humidité (%)')),
                DataColumn(label: Text('Vent (km/h)')),
                DataColumn(label: Text('Précip. (mm)')),
                DataColumn(label: Text('Nuages (%)')),
              ],
              rows: List.generate(times.length, (i) {
                return DataRow(cells: [
                  DataCell(Text(times[i].toString().substring(11, 16))),
                  DataCell(Text(temp.length > i ? temp[i].toString() : '-')),
                  DataCell(Text(appTemp.length > i ? appTemp[i].toString() : '-')),
                  DataCell(Text(humidity.length > i ? humidity[i].toString() : '-')),
                  DataCell(Text(wind.length > i ? wind[i].toString() : '-')),
                  DataCell(Text(precip.length > i ? precip[i].toString() : '-')),
                  DataCell(Text(cloud.length > i ? cloud[i].toString() : '-')),
                ]);
              }),
            ),
          );
  }
}
