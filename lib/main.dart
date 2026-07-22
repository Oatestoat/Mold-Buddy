import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MoldCoachApp());

class MoldCoachApp extends StatelessWidget {
  const MoldCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mold Coach',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F7D6D)),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}


class _AppShellState extends State<AppShell> {
  int index = 0;
  late final MoldAppController controller;

  @override
  void initState() {
    super.initState();
    controller = MoldAppController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(controller: controller),
      TrendsScreen(controller: controller),
      const HabitsScreen(),
      const LearnScreen(),
      DeviceScreen(controller: controller),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Trends'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.sensors_outlined), label: 'Device'),
        ],
      ),
    );
  }
}


class WeatherData {
  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
  });

  final double temperature;
  final double humidity;
  final double precipitation;
  final int weatherCode;

  bool get raining => precipitation > 0 || (weatherCode >= 51 && weatherCode <= 82);
  bool get stormLikely => weatherCode >= 95;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
    );
  }
}

class WeatherService {
  static Future<WeatherData> fetchReadingWeather() async {
    const url =
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=40.3356'
        '&longitude=-75.9269'
        '&current=temperature_2m,relative_humidity_2m,precipitation,weather_code'
        '&temperature_unit=fahrenheit'
        '&precipitation_unit=inch'
        '&timezone=America%2FNew_York';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Weather request failed: ${response.statusCode}');
    }
    return WeatherData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}


class Esp32Reading {
  const Esp32Reading({
    required this.temperatureF,
    required this.humidity,
    required this.pressureHpa,
  });

  final double temperatureF;
  final double humidity;
  final double pressureHpa;

  factory Esp32Reading.fromJson(Map<String, dynamic> json) {
    if (json['connected'] != true) {
      throw Exception(json['error'] ?? 'ESP32 sensor is unavailable.');
    }

    return Esp32Reading(
      temperatureF: (json['temperatureF'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      pressureHpa: (json['pressureHpa'] as num).toDouble(),
    );
  }
}

class Esp32Service {
  static Future<Esp32Reading> fetch(String ipAddress) async {
    final cleanIp = ipAddress
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');

    final response = await http
        .get(Uri.parse('http://$cleanIp/data'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('ESP32 returned status ${response.statusCode}.');
    }

    return Esp32Reading.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class DailyRoomReading {
  const DailyRoomReading({
    required this.date,
    required this.averageHumidity,
    required this.averageTemperature,
    required this.samples,
  });

  final DateTime date;
  final double averageHumidity;
  final double averageTemperature;
  final int samples;
}

class MoldAppController extends ChangeNotifier {
  static const _ipKey = 'esp32_ip';
  static const _selectedRoomKey = 'selected_room';
  static const _roomsKey = 'room_names';
  static const _historyKey = 'room_history';

  String ipAddress = '10.0.0.190';
  String selectedRoom = 'Bedroom';
  List<String> rooms = ['Bedroom', 'Bathroom', 'Basement', 'Kitchen', 'Living room'];

  bool initialized = false;
  bool connected = false;
  bool connecting = false;
  String? connectionError;
  Esp32Reading? latestReading;
  DateTime? lastUpdated;

  Timer? _timer;
  Map<String, dynamic> _history = {};

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    ipAddress = prefs.getString(_ipKey) ?? ipAddress;
    selectedRoom = prefs.getString(_selectedRoomKey) ?? selectedRoom;
    rooms = prefs.getStringList(_roomsKey) ?? rooms;

    if (!rooms.contains(selectedRoom)) {
      rooms.insert(0, selectedRoom);
    }

    final savedHistory = prefs.getString(_historyKey);
    if (savedHistory != null && savedHistory.isNotEmpty) {
      try {
        _history = jsonDecode(savedHistory) as Map<String, dynamic>;
      } catch (_) {
        _history = {};
      }
    }

    initialized = true;
    notifyListeners();

    await testConnection();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refreshReading(silent: true),
    );
  }

  Future<void> setIpAddress(String value) async {
    ipAddress = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ipAddress);
    notifyListeners();
  }

  Future<void> selectRoom(String room) async {
    selectedRoom = room;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedRoomKey, room);
    notifyListeners();
  }

  Future<void> addRoom(String room) async {
    final cleaned = room.trim();
    if (cleaned.isEmpty) return;

    final existing = rooms.where(
      (item) => item.toLowerCase() == cleaned.toLowerCase(),
    );

    final roomToUse = existing.isNotEmpty ? existing.first : cleaned;
    if (!rooms.contains(roomToUse)) {
      rooms = [...rooms, roomToUse];
    }

    selectedRoom = roomToUse;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_roomsKey, rooms);
    await prefs.setString(_selectedRoomKey, selectedRoom);
    notifyListeners();
  }

  Future<void> testConnection() async {
    connecting = true;
    connectionError = null;
    notifyListeners();
    await refreshReading(silent: false);
  }

  Future<void> refreshReading({required bool silent}) async {
    if (!initialized) return;

    if (!silent) {
      connecting = true;
      connectionError = null;
      notifyListeners();
    }

    try {
      final reading = await Esp32Service.fetch(ipAddress);
      latestReading = reading;
      connected = true;
      connecting = false;
      connectionError = null;
      lastUpdated = DateTime.now();
      await _recordReading(selectedRoom, reading);
    } catch (error) {
      connected = false;
      connecting = false;
      connectionError = error.toString().replaceFirst('Exception: ', '');
    }

    notifyListeners();
  }

  Future<void> _recordReading(String room, Esp32Reading reading) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final roomHistory = Map<String, dynamic>.from(
      (_history[room] as Map?)?.cast<String, dynamic>() ?? {},
    );
    final day = Map<String, dynamic>.from(
      (roomHistory[dateKey] as Map?)?.cast<String, dynamic>() ?? {},
    );

    day['humiditySum'] = (day['humiditySum'] as num? ?? 0).toDouble() + reading.humidity;
    day['temperatureSum'] =
        (day['temperatureSum'] as num? ?? 0).toDouble() + reading.temperatureF;
    day['samples'] = (day['samples'] as num? ?? 0).toInt() + 1;

    roomHistory[dateKey] = day;
    _history[room] = roomHistory;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history));
  }

  List<DailyRoomReading> lastSevenDays(String room) {
    final now = DateTime.now();
    final roomHistory = Map<String, dynamic>.from(
      (_history[room] as Map?)?.cast<String, dynamic>() ?? {},
    );

    return List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      final key =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final day = (roomHistory[key] as Map?)?.cast<String, dynamic>();
      final samples = (day?['samples'] as num? ?? 0).toInt();

      return DailyRoomReading(
        date: date,
        averageHumidity: samples == 0
            ? double.nan
            : (day!['humiditySum'] as num).toDouble() / samples,
        averageTemperature: samples == 0
            ? double.nan
            : (day!['temperatureSum'] as num).toDouble() / samples,
        samples: samples,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.controller, super.key});
  final MoldAppController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherData? weather;
  bool loading = true;
  String? weatherError;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_controllerChanged);
    _loadWeather();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
    super.dispose();
  }

  void _controllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadWeather(),
      widget.controller.refreshReading(silent: false),
    ]);
  }

  Future<void> _loadWeather() async {
    setState(() {
      loading = true;
      weatherError = null;
    });

    try {
      final result = await WeatherService.fetchReadingWeather();
      if (!mounted) return;
      setState(() {
        weather = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        weatherError = 'Outdoor weather is unavailable right now.';
        loading = false;
      });
    }
  }

  double get indoorTemperature =>
      widget.controller.latestReading?.temperatureF ?? 74;

  double get indoorHumidity =>
      widget.controller.latestReading?.humidity ?? 59;

  RiskSummary get risk => RiskSummary.fromConditions(
        indoorHumidity: indoorHumidity,
        indoorTemperature: indoorTemperature,
        outdoorHumidity: weather?.humidity,
        raining: weather?.raining ?? false,
      );

  AirflowAdvice get airflow => AirflowAdvice.fromConditions(
        indoorHumidity: indoorHumidity,
        indoorTemperature: indoorTemperature,
        weather: weather,
      );

  @override
  Widget build(BuildContext context) {
    final currentRisk = risk;
    final currentAirflow = airflow;
    final controller = widget.controller;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          _header(),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFE9F4F0),
            child: ListTile(
              leading: const Icon(Icons.meeting_room_outlined),
              title: Text(
                controller.selectedRoom,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                controller.connected
                    ? 'Live ESP32 readings'
                    : 'Waiting for ESP32 connection',
              ),
              trailing: controller.connected
                  ? const Icon(Icons.circle, size: 12, color: Color(0xFF2F7D6D))
                  : const Icon(Icons.circle_outlined, size: 14),
            ),
          ),
          const SizedBox(height: 18),
          MascotCard(mood: currentRisk.mood, message: currentRisk.mascotMessage),
          const SizedBox(height: 18),
          _statusCard(currentRisk),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ConditionsCard(
                  title: controller.selectedRoom,
                  icon: Icons.home_rounded,
                  temperature: indoorTemperature,
                  humidity: indoorHumidity,
                  subtitle: controller.connected
                      ? 'Live from ESP32'
                      : 'ESP32 unavailable',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _outsideCard()),
            ],
          ),
          const SizedBox(height: 18),
          if (!controller.connected)
            Card(
              color: const Color(0xFFFFF4D7),
              child: ListTile(
                leading: const Icon(Icons.sensors_off_outlined),
                title: const Text(
                  'Sensor connection unavailable',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  controller.connectionError ??
                      'Open the Device page to check the IP address.',
                ),
                trailing: IconButton(
                  onPressed: controller.testConnection,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          if (!controller.connected) const SizedBox(height: 18),
          RecommendationCard(advice: currentAirflow),
          const SizedBox(height: 18),
          _whyCard(currentAirflow),
          const SizedBox(height: 18),
          _stormCard(),
          const SizedBox(height: 18),
          _quickActions(),
        ],
      ),
    );
  }

  Widget _header() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Here is how your home is doing today.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: _refreshAll,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _statusCard(RiskSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: summary.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(summary.icon, size: 34, color: summary.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room status',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    summary.label,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: summary.color,
                    ),
                  ),
                  Text(summary.description),
                ],
              ),
            ),
            SizedBox(
              width: 68,
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: summary.score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.black12,
                    color: summary.color,
                  ),
                  Text(
                    '${summary.score}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outsideCard() {
    if (loading) {
      return const Card(
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (weatherError != null || weather == null) {
      return Card(
        child: SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Weather unavailable'),
              TextButton(onPressed: _loadWeather, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return ConditionsCard(
      title: 'Outside',
      icon: weather!.raining
          ? Icons.water_drop_outlined
          : Icons.cloud_outlined,
      temperature: weather!.temperature,
      humidity: weather!.humidity,
      subtitle: weather!.raining ? 'Rain reported' : 'Reading estimate',
    );
  }

  Widget _whyCard(AirflowAdvice advice) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: const Text(
          'Why this recommendation?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _ReasonRow(
            label: 'Indoor humidity',
            value: '${indoorHumidity.round()}%',
          ),
          _ReasonRow(
            label: 'Outdoor humidity',
            value: weather == null
                ? 'Unavailable'
                : '${weather!.humidity.round()}%',
          ),
          _ReasonRow(
            label: 'Outdoor temperature',
            value: weather == null
                ? 'Unavailable'
                : '${weather!.temperature.round()}°F',
          ),
          _ReasonRow(
            label: 'Rain',
            value: weather?.raining == true ? 'Yes' : 'No',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              advice.explanation,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stormCard() {
    final alert = weather?.stormLikely == true || weather?.raining == true;

    return Card(
      color: alert ? const Color(0xFFFFF0F1) : const Color(0xFFEAF2FF),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              alert
                  ? Icons.notification_important_outlined
                  : Icons.notifications_none,
              color: alert
                  ? const Color(0xFFD1495B)
                  : const Color(0xFF4969A8),
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert ? 'Weather alert' : 'Notification preview',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert
                        ? 'Rain or storms are reported. Close windows and check moisture-prone areas.'
                        : 'Phone alerts can later remind users about storms and high humidity.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    const items = [
      (Icons.air, 'Run bathroom fan'),
      (Icons.water_drop_outlined, 'Check condensation'),
      (Icons.cleaning_services_outlined, 'Dry damp surfaces'),
      (Icons.plumbing_outlined, 'Look for leaks'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => ActionChip(
                  avatar: Icon(item.$1, size: 18),
                  label: Text(item.$2),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.$2} added to today’s plan.')),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}


class RiskSummary {
  const RiskSummary({required this.score, required this.label, required this.description, required this.color, required this.icon, required this.mood, required this.mascotMessage});
  final int score;
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final MascotMood mood;
  final String mascotMessage;

  factory RiskSummary.fromConditions({required double indoorHumidity, required double indoorTemperature, double? outdoorHumidity, required bool raining}) {
    int score = 10;
    if (indoorHumidity >= 50) score += 15;
    if (indoorHumidity >= 60) score += 25;
    if (indoorHumidity >= 70) score += 25;
    if (indoorHumidity >= 80) score += 20;
    if (indoorTemperature >= 68 && indoorTemperature <= 86) score += 5;
    if (raining && indoorHumidity >= 60) score += 5;
    if (outdoorHumidity != null && outdoorHumidity >= 80) score += 5;
    score = min(score, 100);

    if (score < 35) {
      return RiskSummary(score: score, label: 'Healthy', description: 'Conditions are less favorable for mold growth.', color: const Color(0xFF2E8B57), icon: Icons.verified_outlined, mood: MascotMood.happy, mascotMessage: 'Nice work! Your room conditions look comfortable today.');
    }
    if (score < 70) {
      return RiskSummary(score: score, label: 'Watch', description: 'Moisture is elevated. A few small actions may help.', color: const Color(0xFFE08A00), icon: Icons.visibility_outlined, mood: MascotMood.concerned, mascotMessage: 'Humidity is creeping up. Let’s improve airflow before it gets worse.');
    }
    return RiskSummary(score: score, label: 'Take action', description: 'Conditions may support mold growth if they stay elevated.', color: const Color(0xFFD1495B), icon: Icons.warning_amber_rounded, mood: MascotMood.alert, mascotMessage: 'Your room needs attention. Check for moisture and reduce humidity soon.');
  }
}

class AirflowAdvice {
  const AirflowAdvice({required this.title, required this.message, required this.explanation, required this.icon, required this.color});
  final String title;
  final String message;
  final String explanation;
  final IconData icon;
  final Color color;

  factory AirflowAdvice.fromConditions({required double indoorHumidity, required double indoorTemperature, required WeatherData? weather}) {
    if (weather == null) {
      return const AirflowAdvice(title: 'Use indoor controls', message: 'Weather is unavailable. Use a fan or dehumidifier if humidity rises.', explanation: 'Without outdoor weather, the app cannot safely compare indoor and outdoor moisture.', icon: Icons.air, color: Color(0xFF5C6BC0));
    }
    if (weather.stormLikely || weather.raining) {
      return const AirflowAdvice(title: 'Keep windows closed', message: 'Rain or storms may bring more moisture inside. Use exhaust fans instead.', explanation: 'Opening windows during rain can raise indoor humidity and wet nearby materials.', icon: Icons.thunderstorm_outlined, color: Color(0xFF546E7A));
    }
    if (weather.humidity >= 70) {
      return const AirflowAdvice(title: 'Keep windows closed', message: 'Outdoor air is humid. Run a fan or dehumidifier instead.', explanation: 'Outdoor humidity is high enough that ventilation may add moisture rather than remove it.', icon: Icons.window_outlined, color: Color(0xFFD1495B));
    }
    if (indoorHumidity >= 60 && weather.humidity < indoorHumidity) {
      return const AirflowAdvice(title: 'Good time to air out', message: 'Outdoor air is drier than indoors. Open windows briefly if it feels comfortable.', explanation: 'Drier outdoor air can help lower indoor humidity when rain is not expected.', icon: Icons.air, color: Color(0xFF2F7D6D));
    }
    if (indoorTemperature > 82 && weather.temperature < indoorTemperature) {
      return const AirflowAdvice(title: 'Brief ventilation may help', message: 'Outside is cooler than indoors. Open windows briefly if outdoor humidity stays low.', explanation: 'Cooler, drier outdoor air may improve comfort and reduce indoor moisture.', icon: Icons.device_thermostat, color: Color(0xFF2F7D6D));
    }
    return const AirflowAdvice(title: 'Keep monitoring', message: 'Conditions are stable. Check again later before changing ventilation.', explanation: 'There is no strong moisture advantage to opening or closing windows right now.', icon: Icons.monitor_heart_outlined, color: Color(0xFF5C6BC0));
  }
}

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({required this.advice, super.key});
  final AirflowAdvice advice;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: advice.color.withValues(alpha: 0.09),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 54, height: 54, decoration: BoxDecoration(color: advice.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)), child: Icon(advice.icon, color: advice.color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Recommended now', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                Text(advice.title, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: advice.color)),
                const SizedBox(height: 6),
                Text(advice.message),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

enum MascotMood { happy, concerned, alert }

class MascotCard extends StatelessWidget {
  const MascotCard({required this.mood, required this.message, super.key});
  final MascotMood mood;
  final String message;

  String get face => switch (mood) {
        MascotMood.happy => '◕‿◕',
        MascotMood.concerned => '◕︵◕',
        MascotMood.alert => '⊙﹏⊙',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE9F4F0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(width: 72, height: 72, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Text(face, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Mold Buddy says', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2F7D6D))), const SizedBox(height: 6), Text(message)])),
          ],
        ),
      ),
    );
  }
}

class ConditionsCard extends StatelessWidget {
  const ConditionsCard({required this.title, required this.icon, required this.temperature, required this.humidity, required this.subtitle, super.key});
  final String title;
  final IconData icon;
  final double temperature;
  final double humidity;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 14),
          Text('${temperature.round()}°F', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text('${humidity.round()}% humidity', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ]),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));
}


class TrendsScreen extends StatefulWidget {
  const TrendsScreen({required this.controller, super.key});
  final MoldAppController controller;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  String _dayLabel(DateTime date) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[date.weekday - 1];
  }

  String _shortDate(DateTime date) => '${date.month}/${date.day}';

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final data = controller.lastSevenDays(controller.selectedRoom);
    final spots = <FlSpot>[
      for (int i = 0; i < data.length; i++)
        if (!data[i].averageHumidity.isNaN)
          FlSpot(i.toDouble(), data[i].averageHumidity),
    ];

    final valid = data.where((item) => !item.averageHumidity.isNaN).toList();
    final improvement = valid.length >= 2
        ? valid.first.averageHumidity - valid.last.averageHumidity
        : null;

    DailyRoomReading? best;
    for (final item in valid) {
      if (best == null || item.averageHumidity < best.averageHumidity) {
        best = item;
      }
    }

    int streak = 0;
    for (final item in valid.reversed) {
      if (item.averageHumidity < 60) {
        streak++;
      } else {
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Text(
          'Humidity trends',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          '${controller.selectedRoom} • daily averages from the ESP32',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: controller.selectedRoom,
          decoration: const InputDecoration(
            labelText: 'Room',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.meeting_room_outlined),
          ),
          items: controller.rooms
              .map(
                (room) => DropdownMenuItem(
                  value: room,
                  child: Text(room),
                ),
              )
              .toList(),
          onChanged: (room) {
            if (room != null) controller.selectRoom(room);
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 18, 14),
            child: SizedBox(
              height: 260,
              child: spots.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved readings for this room yet.\nKeep the app running while the ESP32 is connected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 6,
                        minY: 20,
                        maxY: 100,
                        clipData: const FlClipData.all(),
                        gridData: const FlGridData(
                          show: true,
                          horizontalInterval: 10,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              interval: 20,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.round();
                                if (value != index.toDouble() ||
                                    index < 0 ||
                                    index >= data.length) {
                                  return const SizedBox.shrink();
                                }

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _dayLabel(data[index].date),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      Text(
                                        _shortDate(data[index].date),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: spots.length > 2,
                            barWidth: 4,
                            color: const Color(0xFF2F7D6D),
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2F7D6D)
                                  .withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFFE9F4F0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.insights_outlined,
                  color: Color(0xFF2F7D6D),
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    improvement == null
                        ? 'More than one day of data is needed to calculate progress.'
                        : improvement > 0
                            ? 'Humidity improved by ${improvement.toStringAsFixed(1)} percentage points.'
                            : 'Humidity increased by ${(-improvement).toStringAsFixed(1)} percentage points.',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        InfoCard(
          title: 'Current streak',
          value: '$streak day${streak == 1 ? '' : 's'}',
          subtitle: 'Daily average below 60%',
          icon: Icons.local_fire_department_outlined,
        ),
        const SizedBox(height: 12),
        InfoCard(
          title: 'Best saved day',
          value: best == null ? 'No data' : _shortDate(best.date),
          subtitle: best == null
              ? 'Connect the ESP32 to begin'
              : '${best.averageHumidity.toStringAsFixed(1)}% average humidity',
          icon: Icons.star_outline,
        ),
      ],
    );
  }
}


class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final habits = <String, bool>{
    'Run the bathroom fan after showering': false,
    'Check windows for condensation': false,
    'Look for leaks or water stains': false,
    'Keep furniture away from damp walls': false,
    'Empty the dehumidifier': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in habits.keys) {
      habits[key] = prefs.getBool(key) ?? false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _setHabit(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() => habits[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final completed = habits.values.where((value) => value).length;
    final progress = completed / habits.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Text('Healthy-home habits', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Small actions can prevent bigger moisture problems.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        Card(
          color: const Color(0xFFE9F4F0),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [SizedBox(width: 64, height: 64, child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: Colors.black12, color: const Color(0xFF2F7D6D))), const SizedBox(width: 16), Expanded(child: Text('$completed of ${habits.length} habits completed today', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))]),
          ),
        ),
        const SizedBox(height: 18),
        for (final entry in habits.entries) ...[
          Card(child: CheckboxListTile(value: entry.value, onChanged: (value) => _setHabit(entry.key, value ?? false), title: Text(entry.key), controlAffinity: ListTileControlAffinity.leading)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const topics = [
      ('Why mold grows', 'Mold needs moisture, a suitable temperature, and something organic to grow on.', Icons.science_outlined),
      ('Window condensation', 'Condensation can signal that warm indoor air is meeting a cold surface.', Icons.window_outlined),
      ('Bathroom moisture', 'Run the exhaust fan during a shower and for at least 20 minutes afterward.', Icons.bathtub_outlined),
      ('Basement warning signs', 'Watch for musty odors, damp walls, stains, peeling paint, and recurring condensation.', Icons.foundation_outlined),
      ('Health concerns', 'Long-term dampness and mold exposure may worsen allergies and asthma symptoms.', Icons.health_and_safety_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Text('Learn', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Simple explanations for common mold and moisture questions.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        for (final topic in topics) ...[
          Card(child: ExpansionTile(leading: Icon(topic.$3), title: Text(topic.$1, style: const TextStyle(fontWeight: FontWeight.w800)), childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [Align(alignment: Alignment.centerLeft, child: Text(topic.$2))])),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}


class DeviceScreen extends StatefulWidget {
  const DeviceScreen({required this.controller, super.key});
  final MoldAppController controller;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late final TextEditingController ipController;

  @override
  void initState() {
    super.initState();
    ipController = TextEditingController(text: widget.controller.ipAddress);
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    ipController.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _addRoom() async {
    final roomController = TextEditingController();

    final room = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a room'),
        content: TextField(
          controller: roomController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Room name',
            hintText: 'Example: Upstairs bathroom',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, roomController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    roomController.dispose();
    if (room != null) {
      await widget.controller.addRoom(room);
    }
  }

  Future<void> _test() async {
    await widget.controller.setIpAddress(ipController.text);
    await widget.controller.testConnection();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final reading = controller.latestReading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Text(
          'ESP32 device',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Connect the monitor and choose which room it is measuring.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Card(
          color: controller.connected
              ? const Color(0xFFE9F4F0)
              : const Color(0xFFFFF4D7),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  controller.connected
                      ? Icons.check_circle
                      : Icons.sensors_off_outlined,
                  color: controller.connected
                      ? const Color(0xFF2F7D6D)
                      : const Color(0xFFE08A00),
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    controller.connected
                        ? 'Connected • ${controller.selectedRoom}'
                        : 'ESP32 is not connected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room being monitored',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedRoom,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  items: controller.rooms
                      .map(
                        (room) => DropdownMenuItem(
                          value: room,
                          child: Text(room),
                        ),
                      )
                      .toList(),
                  onChanged: (room) {
                    if (room != null) controller.selectRoom(room);
                  },
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _addRoom,
                  icon: const Icon(Icons.add),
                  label: const Text('Add another room'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Device IP address',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '10.0.0.190',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.connecting ? null : _test,
                    icon: controller.connecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: Text(
                      controller.connecting
                          ? 'Connecting...'
                          : 'Test connection',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (controller.connectionError != null)
                  Text(
                    controller.connectionError!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  )
                else if (reading != null)
                  Text(
                    '${reading.temperatureF.toStringAsFixed(1)}°F • '
                    '${reading.humidity.toStringAsFixed(1)}% humidity • '
                    '${reading.pressureHpa.toStringAsFixed(1)} hPa',
                    style: const TextStyle(
                      color: Color(0xFF2F7D6D),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Use the IP shown in Arduino Serial Monitor.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        InfoCard(
          title: 'Saved room',
          value: controller.selectedRoom,
          subtitle: 'History remains separate for every room',
          icon: Icons.folder_outlined,
        ),
        const SizedBox(height: 12),
        const InfoCard(
          title: 'Data collection',
          value: 'Every 20 sec',
          subtitle: 'Stored as a daily average on this device',
          icon: Icons.data_object,
        ),
        const SizedBox(height: 12),
        const InfoCard(
          title: 'Connection method',
          value: 'Local Wi-Fi',
          subtitle: 'Computer and ESP32 use the same network',
          icon: Icons.wifi,
        ),
      ],
    );
  }
}


class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.value, required this.subtitle, required this.icon, super.key});
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.all(18), leading: Icon(icon, size: 32), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))));
}
