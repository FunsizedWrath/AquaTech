import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _cityController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  Map<String, dynamic>? _weatherData;
  bool _loading = false;
  String? _error;
  List<Map<String, String>> _favoriteCities = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteCities();
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _startTime = null;
    _endTime = null;
  }

  Future<void> _loadFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favoriteCities') ?? [];
    setState(() {
      _favoriteCities = favs.map((e) => Map<String, String>.from(json.decode(e))).toList();
    });
  }

  Future<void> _saveFavoriteCities() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = _favoriteCities.map((e) => json.encode(e)).toList();
    await prefs.setStringList('favoriteCities', favs);
  }

  Future<void> _fetchWeather() async {
    if (_latController.text.isEmpty || _lonController.text.isEmpty) {
      setState(() {
        _error = "Latitude et longitude requises pour la recherche météo.";
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _weatherData = null;
    });
    final lat = _latController.text;
    final lon = _lonController.text;
    final startDate = _startDate?.toIso8601String().split('T').first;
    final endDate = _endDate?.toIso8601String().split('T').first;
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&start_date=$startDate&end_date=$endDate&hourly=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloudcover,windspeed_10m';
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

  Future<void> _fetchLatLonFromCity(String city) async {
    final url = 'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(city)}&limit=1';
    final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        _latController.text = data[0]['lat'];
        _lonController.text = data[0]['lon'];
      } else {
        throw Exception('Ville non trouvée');
      }
    } else {
      throw Exception('Erreur lors de la recherche de la ville');
    }
  }

  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _addFavoriteCity() {
    final city = _cityController.text.trim();
    final lat = _latController.text.trim();
    final lon = _lonController.text.trim();
    if (city.isNotEmpty && lat.isNotEmpty && lon.isNotEmpty) {
      if (!_favoriteCities.any((fav) => fav['city'] == city)) {
        setState(() {
          _favoriteCities.add({'city': city, 'lat': lat, 'lon': lon});
        });
        _saveFavoriteCities();
      }
    }
  }

  void _removeFavoriteCity(String city) {
    setState(() {
      _favoriteCities.removeWhere((fav) => fav['city'] == city);
    });
    _saveFavoriteCities();
  }

  void _selectFavoriteCity(Map<String, String> fav) {
    setState(() {
      _cityController.text = fav['city'] ?? '';
      _latController.text = fav['lat']?.trim() ?? '';
      _lonController.text = fav['lon']?.trim() ?? '';
    });
    if (_latController.text.isNotEmpty && _lonController.text.isNotEmpty) {
      _fetchWeather();
    } else {
      setState(() {
        _error = "Coordonnées invalides pour cette ville favorite.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text('Météo Open-Meteo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB2EBF2), Color(0xFFE1F5FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud, color: Colors.blue, size: 36),
                            SizedBox(width: 8),
                            Text('Recherche météo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: 'Ville (optionnel)',
                                  prefixIcon: Icon(Icons.location_city),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Ajouter aux favoris',
                              icon: const Icon(Icons.star_border, color: Colors.amber),
                              onPressed: _addFavoriteCity,
                            ),
                          ],
                        ),
                        if (_favoriteCities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _favoriteCities.map<Widget>((fav) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ActionChip(
                                  label: Text(fav['city'] ?? ''),
                                  onPressed: () => _selectFavoriteCity(fav),
                                  avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
                                  backgroundColor: Colors.blue.shade50,
                                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _removeFavoriteCity(fav['city'] ?? ''),
                                ),
                              ],
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                decoration: InputDecoration(
                                  labelText: 'Latitude',
                                  prefixIcon: Icon(Icons.my_location),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_cityController.text.isEmpty && (value == null || value.isEmpty)) {
                                    return 'Entrez la latitude ou le nom de la ville';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _lonController,
                                decoration: InputDecoration(
                                  labelText: 'Longitude',
                                  prefixIcon: Icon(Icons.my_location),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_cityController.text.isEmpty && (value == null || value.isEmpty)) {
                                    return 'Entrez la longitude ou le nom de la ville';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
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
                                label: Text(_startDate == null ? 'Date de début' : _startDate!.toString().split(' ')[0]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.access_time),
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _startTime = picked);
                                  }
                                },
                                label: Text(_startTime == null ? 'Heure début' : _startTime!.format(context)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now().add(const Duration(days: 7)),
                                  );
                                  if (picked != null) {
                                    setState(() => _endDate = picked);
                                  }
                                },
                                label: Text(_endDate == null ? 'Date de fin' : _endDate!.toString().split(' ')[0]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.access_time),
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _endTime = picked);
                                  }
                                },
                                label: Text(_endTime == null ? 'Heure fin' : _endTime!.format(context)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
                                    if (_cityController.text.isNotEmpty) {
                                      try {
                                        await _fetchLatLonFromCity(_cityController.text);
                                      } catch (e) {
                                        setState(() {
                                          _error = e.toString();
                                        });
                                        return;
                                      }
                                    }
                                    _fetchWeather();
                                  }
                                },
                          icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
                          label: const Text('Obtenir la météo', style: TextStyle(fontSize: 18)),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                        if (_weatherData != null) ...[
                          const SizedBox(height: 32),
                          const Text('Données météo :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 8),
                          WeatherDataTable(
                            weatherData: _weatherData!,
                            startDateTime: _combineDateTime(_startDate, _startTime),
                            endDateTime: _combineDateTime(_endDate, _endTime),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}

class WeatherDataTable extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  const WeatherDataTable({super.key, required this.weatherData, this.startDateTime, this.endDateTime});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final hourly = weatherData['hourly'] ?? {};
    final times = (hourly['time'] as List?) ?? [];
    final temp = (hourly['temperature_2m'] as List?) ?? [];
    final appTemp = (hourly['apparent_temperature'] as List?) ?? [];
    final humidity = (hourly['relative_humidity_2m'] as List?) ?? [];
    final wind = (hourly['windspeed_10m'] as List?) ?? [];
    final precip = (hourly['precipitation'] as List?) ?? [];
    final cloud = (hourly['cloudcover'] as List?) ?? [];
    List<int> filteredIndexes = [];
    for (int i = 0; i < times.length; i++) {
      final dt = DateTime.tryParse(times[i]);
      if (dt != null &&
          (startDateTime == null || !dt.isBefore(startDateTime!)) &&
          (endDateTime == null || !dt.isAfter(endDateTime!))) {
        filteredIndexes.add(i);
      }
    }
    return filteredIndexes.isEmpty
        ? const Text('Aucune donnée disponible.')
        : LayoutBuilder(
            builder: (context, constraints) {
              final table = DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Heure', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Temp. (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ressentie (°C)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Humidité (%)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Vent (km/h)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Précipitations (mm)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nuages (%)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filteredIndexes.map((i) {
                  return DataRow(cells: [
                    DataCell(Text(times[i].toString().replaceFirst('T', ' '))),
                    DataCell(Text(temp.length > i ? temp[i].toString() : '-')),
                    DataCell(Text(appTemp.length > i ? appTemp[i].toString() : '-')),
                    DataCell(Text(humidity.length > i ? humidity[i].toString() : '-')),
                    DataCell(Text(wind.length > i ? wind[i].toString() : '-')),
                    DataCell(Text(precip.length > i ? precip[i].toString() : '-')),
                    DataCell(Text(cloud.length > i ? cloud[i].toString() : '-')),
                  ]);
                }).toList(),
              );
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: table,
                  ),
                ),
              );
            },
          );
  }
}
