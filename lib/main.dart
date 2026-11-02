import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MoldCoachApp());

/// ---------------------------------------------------------------------
/// Design tokens
///
/// A small, named palette instead of a generic seeded Material theme.
/// "Damp home" made legible rather than clinical: deep mossy greens,
/// a warm paper background, and a clay accent for anything that needs
/// attention.
/// ---------------------------------------------------------------------
class Palette {
  Palette._();

  static const ink = Color(0xFF26312B); // near-black, warm green cast
  static const moss = Color(0xFF5F8C78); // primary
  static const mossDeep = Color(0xFF3E6555); // pressed / dark accents
  static const mossPale = Color(0xFFEAF3EE); // tinted surfaces
  static const sage = Color(0xFFAEC7B8); // muted secondary
  static const paper = Color(0xFFF7F6F1); // background (not the cliché cream)
  static const card = Color(0xFFFFFFFF);
  static const clay = Color(0xFFB96B5A); // alert / take-action
  static const amber = Color(0xFFC69A52); // watch / caution
  static const mist = Color(0xFF718B94); // informational blue-grey
  static const inkFaint = Color(0xFF718078);
  static const glow = Color(0xFFDDEBE2);
  static const softMint = Color(0xFFF1F7F3);
}

class MoldCoachApp extends StatelessWidget {
  const MoldCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mold Buddy',
      theme: base.copyWith(
        scaffoldBackgroundColor: Palette.paper,
        colorScheme: base.colorScheme.copyWith(
          primary: Palette.moss,
          secondary: Palette.clay,
          surface: Palette.card,
        ),
        textTheme: base.textTheme
            .apply(
              bodyColor: Palette.ink,
              displayColor: Palette.ink,
            )
            .copyWith(
              headlineMedium: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.08,
              ),
              titleLarge: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              bodyMedium: const TextStyle(height: 1.35),
            ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Palette.card,
          indicatorColor: Palette.mossPale,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? Palette.mossDeep : Palette.inkFaint,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Palette.mossDeep : Palette.inkFaint,
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Palette.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE3DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE3DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Palette.moss, width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Palette.mossDeep,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: Palette.mossPale,
          labelStyle: const TextStyle(
            color: Palette.mossDeep,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      home: const LaunchScreen(),
    );
  }
}


class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _blinkController;
  bool _showApp = false;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (mounted) _blinkController.forward(from: 0);
    });

    Future<void>.delayed(const Duration(milliseconds: 2350), () {
      if (mounted) setState(() => _showApp = true);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) {
      return const AppShell();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4F8F2),
              Color(0xFFE3EEE4),
              Color(0xFFD5E5D8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([
                  _floatController,
                  _blinkController,
                ]),
                builder: (context, child) {
                  final lift =
                      -7.0 + (_floatController.value * 14.0);
                  final scale =
                      0.96 + (_floatController.value * 0.05);

                  return Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.scale(
                      scale: scale,
                      child: Moldling(
                        mood: MascotMood.happy,
                        size: 138,
                        blink: _blinkController.value > 0.35 &&
                            _blinkController.value < 0.8,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Mold Buddy',
                style: TextStyle(
                  color: Palette.mossDeep,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Waking up your home monitor',
                style: TextStyle(
                  color: Palette.inkFaint,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const _LoadingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (controller.value + index * 0.22) % 1.0;
            final scale =
                0.7 + (0.55 * sin(phase * pi).abs());

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Palette.mossDeep,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey(index),
            child: pages[index],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 72,
        backgroundColor: const Color(0xFFFAFBF8),
        indicatorColor: Palette.mossPale,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors_rounded),
            label: 'Device',
          ),
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

enum DeviceDisplayMode {
  auto,
  face,
  temperature,
  humidity,
  risk,
  pressure,
  advice,
}

extension DeviceDisplayModeInfo on DeviceDisplayMode {
  String get apiValue => switch (this) {
        DeviceDisplayMode.auto => 'auto',
        DeviceDisplayMode.face => 'face',
        DeviceDisplayMode.temperature => 'temperature',
        DeviceDisplayMode.humidity => 'humidity',
        DeviceDisplayMode.risk => 'risk',
        DeviceDisplayMode.pressure => 'pressure',
        DeviceDisplayMode.advice => 'advice',
      };

  String get title => switch (this) {
        DeviceDisplayMode.auto => 'Auto cycle',
        DeviceDisplayMode.face => 'Mold Buddy',
        DeviceDisplayMode.temperature => 'Temperature',
        DeviceDisplayMode.humidity => 'Humidity',
        DeviceDisplayMode.risk => 'Mold risk',
        DeviceDisplayMode.pressure => 'Pressure',
        DeviceDisplayMode.advice => 'Tips',
      };

  String get subtitle => switch (this) {
        DeviceDisplayMode.auto => 'Cycle through all OLED screens',
        DeviceDisplayMode.face => 'Keep the Mold Buddy on screen',
        DeviceDisplayMode.temperature => 'Show live room temperature',
        DeviceDisplayMode.humidity => 'Show live relative humidity',
        DeviceDisplayMode.risk => 'Show the current mold-risk status',
        DeviceDisplayMode.pressure => 'Show current air pressure',
        DeviceDisplayMode.advice => 'Show the current prevention tip',
      };

  IconData get icon => switch (this) {
        DeviceDisplayMode.auto => Icons.autorenew,
        DeviceDisplayMode.face => Icons.sentiment_satisfied_alt,
        DeviceDisplayMode.temperature => Icons.device_thermostat,
        DeviceDisplayMode.humidity => Icons.water_drop_outlined,
        DeviceDisplayMode.risk => Icons.shield_outlined,
        DeviceDisplayMode.pressure => Icons.speed,
        DeviceDisplayMode.advice => Icons.lightbulb_outline,
      };
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

  static Future<void> setDisplayMode(
    String ipAddress,
    DeviceDisplayMode mode,
  ) async {
    final cleanIp = ipAddress
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');

    final response = await http
        .get(
          Uri.parse(
            'http://$cleanIp/display?mode=${Uri.encodeQueryComponent(mode.apiValue)}',
          ),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception(
        'ESP32 display command failed: ${response.statusCode}.',
      );
    }
  }
}


class RoomLogEntry {
  const RoomLogEntry({
    required this.type,
    required this.timestamp,
    this.note = '',
  });

  final String type;
  final DateTime timestamp;
  final String note;

  Map<String, dynamic> toJson() => {
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory RoomLogEntry.fromJson(Map<String, dynamic> json) {
    return RoomLogEntry(
      type: json['type'] as String? ?? 'Note',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}

class TodayRoomSummary {
  const TodayRoomSummary({
    required this.averageHumidity,
    required this.averageTemperature,
    required this.samples,
    required this.estimatedMinutesAbove60,
    required this.estimatedMinutesAbove70,
  });

  final double? averageHumidity;
  final double? averageTemperature;
  final int samples;
  final int estimatedMinutesAbove60;
  final int estimatedMinutesAbove70;
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
  static const _displayModeKey = 'display_mode';
  static const _journalKey = 'room_journal';

  String ipAddress = '10.0.0.190';
  String selectedRoom = 'Bedroom';
  List<String> rooms = ['Bedroom', 'Bathroom', 'Basement', 'Kitchen', 'Living room'];

  bool initialized = false;
  bool connected = false;
  bool connecting = false;
  String? connectionError;
  Esp32Reading? latestReading;
  DateTime? lastUpdated;

  DeviceDisplayMode displayMode = DeviceDisplayMode.auto;
  bool changingDisplayMode = false;
  String? displayModeError;

  Timer? _timer;
  Map<String, dynamic> _history = {};
  Map<String, dynamic> _journal = {};

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    ipAddress = prefs.getString(_ipKey) ?? ipAddress;
    selectedRoom = prefs.getString(_selectedRoomKey) ?? selectedRoom;
    rooms = prefs.getStringList(_roomsKey) ?? rooms;

    final savedDisplayMode = prefs.getString(_displayModeKey);
    if (savedDisplayMode != null) {
      for (final mode in DeviceDisplayMode.values) {
        if (mode.apiValue == savedDisplayMode) {
          displayMode = mode;
          break;
        }
      }
    }

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

    final savedJournal = prefs.getString(_journalKey);
    if (savedJournal != null && savedJournal.isNotEmpty) {
      try {
        _journal = jsonDecode(savedJournal) as Map<String, dynamic>;
      } catch (_) {
        _journal = {};
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

  Future<void> setDeviceDisplayMode(DeviceDisplayMode mode) async {
    changingDisplayMode = true;
    displayModeError = null;
    notifyListeners();

    try {
      await Esp32Service.setDisplayMode(ipAddress, mode);
      displayMode = mode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_displayModeKey, mode.apiValue);
    } catch (error) {
      displayModeError =
          error.toString().replaceFirst('Exception: ', '');
    } finally {
      changingDisplayMode = false;
      notifyListeners();
    }
  }

  Future<void> testConnection() async {
    connecting = true;
    connectionError = null;
    notifyListeners();

    await refreshReading(silent: false);

    if (connected) {
      try {
        await Esp32Service.setDisplayMode(ipAddress, displayMode);
      } catch (_) {
        // Connection can still be considered valid if the display command fails.
      }
    }
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

    if (reading.humidity >= 60) {
      day['above60Samples'] =
          (day['above60Samples'] as num? ?? 0).toInt() + 1;
    }

    if (reading.humidity >= 70) {
      day['above70Samples'] =
          (day['above70Samples'] as num? ?? 0).toInt() + 1;
    }

    roomHistory[dateKey] = day;
    _history[room] = roomHistory;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history));
  }


  Future<void> logRoomEvent(
    String type, {
    String note = '',
  }) async {
    final current = List<dynamic>.from(
      _journal[selectedRoom] as List<dynamic>? ?? const [],
    );

    current.insert(
      0,
      RoomLogEntry(
        type: type,
        timestamp: DateTime.now(),
        note: note.trim(),
      ).toJson(),
    );

    // Keep the local journal lightweight.
    if (current.length > 40) {
      current.removeRange(40, current.length);
    }

    _journal[selectedRoom] = current;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_journalKey, jsonEncode(_journal));
    notifyListeners();
  }

  List<RoomLogEntry> recentRoomEvents(
    String room, {
    int limit = 5,
  }) {
    final raw = List<dynamic>.from(
      _journal[room] as List<dynamic>? ?? const [],
    );

    return raw
        .take(limit)
        .map(
          (entry) => RoomLogEntry.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
  }

  TodayRoomSummary todaySummary(String room) {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final roomHistory = Map<String, dynamic>.from(
      (_history[room] as Map?)?.cast<String, dynamic>() ?? {},
    );

    final day = (roomHistory[dateKey] as Map?)?.cast<String, dynamic>();
    final samples = (day?['samples'] as num? ?? 0).toInt();

    if (samples == 0 || day == null) {
      return const TodayRoomSummary(
        averageHumidity: null,
        averageTemperature: null,
        samples: 0,
        estimatedMinutesAbove60: 0,
        estimatedMinutesAbove70: 0,
      );
    }

    // The app samples every ~20 seconds while it is open.
    // 3 samples ≈ 1 monitored minute.
    final above60 = (day['above60Samples'] as num? ?? 0).toInt();
    final above70 = (day['above70Samples'] as num? ?? 0).toInt();

    return TodayRoomSummary(
      averageHumidity:
          (day['humiditySum'] as num).toDouble() / samples,
      averageTemperature:
          (day['temperatureSum'] as num).toDouble() / samples,
      samples: samples,
      estimatedMinutesAbove60: (above60 / 3).round(),
      estimatedMinutesAbove70: (above70 / 3).round(),
    );
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


/// ---------------------------------------------------------------------
/// Mascot
///
/// An original character (not a reproduction of any existing studio's
/// design): a round, fuzzy "Mold Buddy" with wispy dust-bunny tendrils
/// and two big expressive eyes. Its posture and eyes shift with mood.
/// ---------------------------------------------------------------------
enum MascotMood { happy, concerned, alert }

class Moldling extends StatelessWidget {
  const Moldling({
    required this.mood,
    this.size = 76,
    this.blink = false,
    super.key,
  });

  final MascotMood mood;
  final double size;
  final bool blink;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoldlingPainter(
          mood: mood,
          blink: blink,
        ),
      ),
    );
  }
}

class _MoldlingPainter extends CustomPainter {
  _MoldlingPainter({
    required this.mood,
    required this.blink,
  });

  final MascotMood mood;
  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2 + size.height * 0.04,
    );

    final bodyW = size.width * 0.58;
    final bodyH = size.height * 0.48;

    final bodyColor = switch (mood) {
      MascotMood.happy => const Color(0xFF678F7D),
      MascotMood.concerned => const Color(0xFF7E8F7D),
      MascotMood.alert => const Color(0xFF8E756D),
    };

    // Soft shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + bodyH * 0.60),
        width: bodyW * 0.82,
        height: bodyH * 0.22,
      ),
      Paint()
        ..color = Palette.ink.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        ),
    );

    // Curved tiny legs. The silhouette is spider-ish, but the
    // body reads more like a soft mold puff / fuzzy pet.
    final legPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.032
      ..strokeCap = StrokeCap.round;

    final legPairs = <(Offset, Offset, Offset)>[
      (
        Offset(center.dx - bodyW * 0.38, center.dy - bodyH * 0.10),
        Offset(center.dx - bodyW * 0.63, center.dy - bodyH * 0.23),
        Offset(center.dx - bodyW * 0.77, center.dy - bodyH * 0.12),
      ),
      (
        Offset(center.dx - bodyW * 0.43, center.dy + bodyH * 0.12),
        Offset(center.dx - bodyW * 0.69, center.dy + bodyH * 0.08),
        Offset(center.dx - bodyW * 0.80, center.dy + bodyH * 0.25),
      ),
      (
        Offset(center.dx - bodyW * 0.30, center.dy + bodyH * 0.34),
        Offset(center.dx - bodyW * 0.48, center.dy + bodyH * 0.52),
        Offset(center.dx - bodyW * 0.61, center.dy + bodyH * 0.50),
      ),
      (
        Offset(center.dx + bodyW * 0.38, center.dy - bodyH * 0.10),
        Offset(center.dx + bodyW * 0.63, center.dy - bodyH * 0.23),
        Offset(center.dx + bodyW * 0.77, center.dy - bodyH * 0.12),
      ),
      (
        Offset(center.dx + bodyW * 0.43, center.dy + bodyH * 0.12),
        Offset(center.dx + bodyW * 0.69, center.dy + bodyH * 0.08),
        Offset(center.dx + bodyW * 0.80, center.dy + bodyH * 0.25),
      ),
      (
        Offset(center.dx + bodyW * 0.30, center.dy + bodyH * 0.34),
        Offset(center.dx + bodyW * 0.48, center.dy + bodyH * 0.52),
        Offset(center.dx + bodyW * 0.61, center.dy + bodyH * 0.50),
      ),
    ];

    for (final leg in legPairs) {
      final path = Path()
        ..moveTo(leg.$1.dx, leg.$1.dy)
        ..quadraticBezierTo(
          leg.$2.dx,
          leg.$2.dy,
          leg.$3.dx,
          leg.$3.dy,
        );
      canvas.drawPath(path, legPaint);
    }

    // Mold-puff lobes around the body edge.
    final puffPaint = Paint()..color = bodyColor;

    final puffCenters = [
      Offset(center.dx - bodyW * 0.30, center.dy - bodyH * 0.28),
      Offset(center.dx, center.dy - bodyH * 0.38),
      Offset(center.dx + bodyW * 0.30, center.dy - bodyH * 0.28),
      Offset(center.dx - bodyW * 0.40, center.dy + bodyH * 0.03),
      Offset(center.dx + bodyW * 0.40, center.dy + bodyH * 0.03),
      Offset(center.dx - bodyW * 0.23, center.dy + bodyH * 0.30),
      Offset(center.dx + bodyW * 0.23, center.dy + bodyH * 0.30),
    ];

    for (final p in puffCenters) {
      canvas.drawCircle(
        p,
        size.width * 0.13,
        puffPaint,
      );
    }

    // Main soft body.
    final bodyRect = Rect.fromCenter(
      center: center,
      width: bodyW,
      height: bodyH,
    );

    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.42),
          radius: 1.15,
          colors: [
            bodyColor.withValues(alpha: 0.83),
            bodyColor,
          ],
        ).createShader(bodyRect),
    );

    // A couple tiny pale "spore" dots make it read as mold.
    final sporePaint = Paint()
      ..color = const Color(0xFFD7E9DD).withValues(alpha: 0.68);

    canvas.drawCircle(
      Offset(center.dx - bodyW * 0.24, center.dy - bodyH * 0.24),
      size.width * 0.025,
      sporePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + bodyW * 0.27, center.dy - bodyH * 0.30),
      size.width * 0.018,
      sporePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + bodyW * 0.36, center.dy + bodyH * 0.20),
      size.width * 0.015,
      sporePaint,
    );

    // Oversized friendly eyes.
    final eyeY = center.dy - bodyH * 0.04;
    final eyeX = bodyW * 0.22;
    final eyeR = size.width * 0.115;

    final leftEye = Offset(center.dx - eyeX, eyeY);
    final rightEye = Offset(center.dx + eyeX, eyeY);

    final whitePaint = Paint()..color = const Color(0xFFFDFEFA);

    if (blink) {
      final blinkPaint = Paint()
        ..color = const Color(0xFFFDFEFA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.028
        ..strokeCap = StrokeCap.round;

      for (final eye in [leftEye, rightEye]) {
        canvas.drawArc(
          Rect.fromCenter(
            center: eye,
            width: eyeR * 1.45,
            height: eyeR * 0.75,
          ),
          0.10,
          pi - 0.20,
          false,
          blinkPaint,
        );
      }
    } else {
      canvas.drawCircle(leftEye, eyeR, whitePaint);
      canvas.drawCircle(rightEye, eyeR, whitePaint);

      final pupilPaint = Paint()..color = Palette.ink;

      final pupilShift = switch (mood) {
        MascotMood.happy => Offset(0, eyeR * 0.08),
        MascotMood.concerned => Offset(0, eyeR * 0.17),
        MascotMood.alert => Offset.zero,
      };

      final pupilR = eyeR *
          switch (mood) {
            MascotMood.happy => 0.50,
            MascotMood.concerned => 0.46,
            MascotMood.alert => 0.57,
          };

      for (final eye in [leftEye, rightEye]) {
        canvas.drawCircle(
          eye + pupilShift,
          pupilR,
          pupilPaint,
        );

        canvas.drawCircle(
          eye +
              pupilShift +
              Offset(
                -pupilR * 0.30,
                -pupilR * 0.35,
              ),
          pupilR * 0.24,
          Paint()..color = Colors.white,
        );
      }
    }

    // Very small mouth = cuter / less virus-y.
    final mouthPaint = Paint()
      ..color = const Color(0xFFFDFEFA).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.021
      ..strokeCap = StrokeCap.round;

    final mouthY = center.dy + bodyH * 0.28;

    if (mood == MascotMood.happy) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, mouthY),
          width: bodyW * 0.22,
          height: bodyH * 0.16,
        ),
        0.05,
        pi - 0.10,
        false,
        mouthPaint,
      );
    } else if (mood == MascotMood.concerned) {
      canvas.drawLine(
        Offset(center.dx - bodyW * 0.08, mouthY),
        Offset(center.dx + bodyW * 0.08, mouthY),
        mouthPaint,
      );
    } else {
      canvas.drawCircle(
        Offset(center.dx, mouthY),
        size.width * 0.035,
        Paint()..color = const Color(0xFFFDFEFA),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoldlingPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.blink != blink;
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
      color: Palette.mossDeep,
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          _header(),
          const SizedBox(height: 16),
          _roomPill(controller),
          const SizedBox(height: 16),
          MascotCard(mood: currentRisk.mood, message: currentRisk.mascotMessage),
          const SizedBox(height: 14),
          _statusCard(currentRisk),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ConditionsCard(
                  title: controller.selectedRoom,
                  icon: Icons.home_rounded,
                  temperature: indoorTemperature,
                  humidity: indoorHumidity,
                  accent: Palette.moss,
                  subtitle: controller.connected
                      ? 'Live from ESP32'
                      : 'ESP32 unavailable',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _outsideCard()),
            ],
          ),
          const SizedBox(height: 14),
          _todayStoryCard(controller),
          const SizedBox(height: 14),
          _roomJournalCard(controller),
          const SizedBox(height: 14),
          if (!controller.connected)
            Card(
              color: const Color(0xFFFCF1DD),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                leading: const Icon(Icons.sensors_off_outlined, color: Palette.amber),
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
          if (!controller.connected) const SizedBox(height: 14),
          RecommendationCard(advice: currentAirflow),
          const SizedBox(height: 14),
          _whyCard(currentAirflow),
          const SizedBox(height: 14),
          _stormCard(),
          const SizedBox(height: 22),
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
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Here is how your home is doing today.',
                style: TextStyle(color: Palette.inkFaint),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Palette.mossPale,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh, color: Palette.mossDeep),
          ),
        ),
      ],
    );
  }

  Widget _roomPill(MoldAppController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Palette.mossDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.selectedRoom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  controller.connected ? 'Live ESP32 readings' : 'Waiting for ESP32 connection',
                  style: const TextStyle(color: Color(0xFFCFE0D5), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.connected ? const Color(0xFF7FD8A6) : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(RiskSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: summary.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(summary.icon, size: 30, color: summary.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room status',
                    style: TextStyle(
                      color: Palette.inkFaint,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    summary.label,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: summary.color,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(summary.description, style: const TextStyle(color: Palette.inkFaint)),
                ],
              ),
            ),
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: summary.score / 100,
                    strokeWidth: 7,
                    backgroundColor: Palette.mossPale,
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
          child: Center(child: CircularProgressIndicator(color: Palette.mossDeep)),
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
              const Text('Weather unavailable', style: TextStyle(color: Palette.inkFaint)),
              TextButton(
                onPressed: _loadWeather,
                style: TextButton.styleFrom(foregroundColor: Palette.mossDeep),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return ConditionsCard(
      title: 'Outside',
      icon: weather!.raining ? Icons.water_drop_outlined : Icons.cloud_outlined,
      temperature: weather!.temperature,
      humidity: weather!.humidity,
      accent: Palette.mist,
      subtitle: weather!.raining ? 'Rain reported' : 'Reading estimate',
    );
  }


  Widget _todayStoryCard(MoldAppController controller) {
    final summary = controller.todaySummary(controller.selectedRoom);

    return Container(
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Palette.mossPale,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Palette.mossPale,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Palette.mossDeep,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today’s moisture story',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'A quick summary of the time this app has monitored this room.',
                      style: TextStyle(
                        color: Palette.inkFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (summary.samples == 0)
            const Text(
              'No readings saved for this room yet. Keep the app open while the ESP32 is connected.',
              style: TextStyle(color: Palette.inkFaint),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Avg humidity',
                    value:
                        '${summary.averageHumidity!.toStringAsFixed(0)}%',
                    icon: Icons.water_drop_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Above 60%',
                    value:
                        '~${summary.estimatedMinutesAbove60} min',
                    icon: Icons.timelapse_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Above 70%',
                    value:
                        '~${summary.estimatedMinutesAbove70} min',
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _todayPulseCard(MoldAppController controller) {
    final humidity = controller.latestReading?.humidity ?? 0;
    final temp = controller.latestReading?.temperatureF ?? 0;

    final humidityLabel = humidity >= 70
        ? 'Very humid'
        : humidity >= 60
            ? 'Getting humid'
            : humidity >= 40
                ? 'Comfortable'
                : 'A little dry';

    final humidityIcon = humidity >= 60
        ? Icons.water_drop_rounded
        : Icons.eco_outlined;

    final action = humidity >= 70
        ? 'Run a fan or dehumidifier if you can.'
        : humidity >= 60
            ? 'Check windows, bathrooms, and other damp spots.'
            : 'Conditions look steady. Keep an eye on moisture sources.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F2),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDDE9E1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Palette.mossDeep,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your room right now',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'A quick read, without the science-y overload.',
                      style: TextStyle(
                        color: Palette.inkFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _miniLiveTile(
                  icon: humidityIcon,
                  value: humidity > 0 ? '${humidity.toStringAsFixed(0)}%' : '--',
                  label: humidityLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniLiveTile(
                  icon: Icons.thermostat_rounded,
                  value: temp > 0 ? '${temp.toStringAsFixed(0)}°F' : '--',
                  label: 'Indoor temp',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 19,
                  color: Palette.mossDeep,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLiveTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Palette.mossDeep,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Palette.inkFaint,
              fontSize: 11.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomJournalCard(MoldAppController controller) {
    final events = controller.recentRoomEvents(
      controller.selectedRoom,
      limit: 3,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFECE6D9),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Room journal',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Add context to ${controller.selectedRoom.toLowerCase()} humidity changes.',
                      style: const TextStyle(
                        color: Palette.inkFaint,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _showRoomEventSheet,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text('Log'),
              ),
            ],
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (var i = 0; i < events.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Palette.mossPale,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _eventIcon(events[i].type),
                      size: 17,
                      color: Palette.mossDeep,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events[i].type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        if (events[i].note.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            events[i].note,
                            style: const TextStyle(
                              color: Palette.inkFaint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatEventTime(events[i].timestamp),
                    style: const TextStyle(
                      color: Palette.inkFaint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (i != events.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: Color(0xFFE8E3D8),
                  ),
                ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            const Text(
              'Nothing logged yet. Try noting a shower, condensation, a leak, or when you run a dehumidifier.',
              style: TextStyle(
                color: Palette.inkFaint,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _eventIcon(String type) {
    if (type.contains('Shower')) return Icons.bathtub_outlined;
    if (type.contains('Window')) return Icons.window_outlined;
    if (type.contains('Fan')) return Icons.air_rounded;
    if (type.contains('Condensation')) return Icons.water_drop_outlined;
    if (type.contains('Leak')) return Icons.plumbing_outlined;
    if (type.contains('Musty')) return Icons.sensors_outlined;
    return Icons.edit_note_rounded;
  }

  String _formatEventTime(DateTime time) {
    final now = DateTime.now();
    final sameDay = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;

    final hour12 = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';

    if (sameDay) {
      return '$hour12:$minute $amPm';
    }
    return '${time.month}/${time.day}';
  }

  Future<void> _showRoomEventSheet() async {
    const options = [
      ('Shower or bath', Icons.bathtub_outlined),
      ('Window opened', Icons.window_outlined),
      ('Fan / dehumidifier on', Icons.air_rounded),
      ('Condensation seen', Icons.water_drop_outlined),
      ('Leak or water found', Icons.plumbing_outlined),
      ('Musty smell', Icons.sensors_outlined),
    ];

    final selection = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFBFAF6),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  26,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Palette.inkFaint.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'What happened in this room?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.controller.selectedRoom,
                    style: const TextStyle(
                      color: Palette.inkFaint,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final option in options) ...[
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                            option.$1,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Palette.mossPale,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  option.$2,
                                  color: Palette.mossDeep,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  option.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Palette.inkFaint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    if (selection != null) {
      await widget.controller.logRoomEvent(selection);
    }
  }

  Widget _whyCard(AirflowAdvice advice) {
    return Card(
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
        leading: const Icon(Icons.help_outline, color: Palette.mossDeep),
        title: const Text(
          'Why this recommendation?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _ReasonRow(label: 'Indoor humidity', value: '${indoorHumidity.round()}%'),
          _ReasonRow(
            label: 'Outdoor humidity',
            value: weather == null ? 'Unavailable' : '${weather!.humidity.round()}%',
          ),
          _ReasonRow(
            label: 'Outdoor temperature',
            value: weather == null ? 'Unavailable' : '${weather!.temperature.round()}°F',
          ),
          _ReasonRow(label: 'Rain', value: weather?.raining == true ? 'Yes' : 'No'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(advice.explanation, style: const TextStyle(color: Palette.inkFaint)),
          ),
        ],
      ),
    );
  }

  Widget _stormCard() {
    final alert = weather?.stormLikely == true || weather?.raining == true;

    return Card(
      color: alert ? const Color(0xFFFBEAE7) : Palette.mossPale,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              alert ? Icons.notification_important_outlined : Icons.notifications_none,
              color: alert ? Palette.clay : Palette.mossDeep,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert ? 'Weather alert' : 'Notification preview',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert
                        ? 'Rain or storms are reported. Close windows and check moisture-prone areas.'
                        : 'Phone alerts can later remind users about storms and high humidity.',
                    style: const TextStyle(color: Palette.inkFaint),
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
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => ActionChip(
                  avatar: Icon(item.$1, size: 18, color: Palette.mossDeep),
                  label: Text(item.$2),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.$2} added to today\u2019s plan.')),
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
  const RiskSummary({
    required this.score,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.mood,
    required this.mascotMessage,
  });

  final int score;
  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final MascotMood mood;
  final String mascotMessage;

  factory RiskSummary.fromConditions({
    required double indoorHumidity,
    required double indoorTemperature,
    double? outdoorHumidity,
    required bool raining,
  }) {
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
      return RiskSummary(
        score: score,
        label: 'Healthy',
        description: 'Conditions are less favorable for mold growth.',
        color: Palette.moss,
        icon: Icons.verified_outlined,
        mood: MascotMood.happy,
        mascotMessage: 'Nice work! Your room conditions look comfortable today.',
      );
    }
    if (score < 70) {
      return RiskSummary(
        score: score,
        label: 'Watch',
        description: 'Moisture is elevated. A few small actions may help.',
        color: Palette.amber,
        icon: Icons.visibility_outlined,
        mood: MascotMood.concerned,
        mascotMessage: 'Humidity is creeping up. Let\u2019s improve airflow before it gets worse.',
      );
    }
    return RiskSummary(
      score: score,
      label: 'Take action',
      description: 'Conditions may support mold growth if they stay elevated.',
      color: Palette.clay,
      icon: Icons.warning_amber_rounded,
      mood: MascotMood.alert,
      mascotMessage: 'Your room needs attention. Check for moisture and reduce humidity soon.',
    );
  }
}

class AirflowAdvice {
  const AirflowAdvice({
    required this.title,
    required this.message,
    required this.explanation,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final String explanation;
  final IconData icon;
  final Color color;

  factory AirflowAdvice.fromConditions({
    required double indoorHumidity,
    required double indoorTemperature,
    required WeatherData? weather,
  }) {
    if (weather == null) {
      return const AirflowAdvice(
        title: 'Use indoor controls',
        message: 'Weather is unavailable. Use a fan or dehumidifier if humidity rises.',
        explanation: 'Without outdoor weather, the app cannot safely compare indoor and outdoor moisture.',
        icon: Icons.air,
        color: Palette.mist,
      );
    }
    if (weather.stormLikely || weather.raining) {
      return const AirflowAdvice(
        title: 'Keep windows closed',
        message: 'Rain or storms may bring more moisture inside. Use exhaust fans instead.',
        explanation: 'Opening windows during rain can raise indoor humidity and wet nearby materials.',
        icon: Icons.thunderstorm_outlined,
        color: Color(0xFF546E7A),
      );
    }
    if (weather.humidity >= 70) {
      return const AirflowAdvice(
        title: 'Keep windows closed',
        message: 'Outdoor air is humid. Run a fan or dehumidifier instead.',
        explanation: 'Outdoor humidity is high enough that ventilation may add moisture rather than remove it.',
        icon: Icons.window_outlined,
        color: Palette.clay,
      );
    }
    if (indoorHumidity >= 60 && weather.humidity < indoorHumidity) {
      return const AirflowAdvice(
        title: 'Good time to air out',
        message: 'Outdoor air is drier than indoors. Open windows briefly if it feels comfortable.',
        explanation: 'Drier outdoor air can help lower indoor humidity when rain is not expected.',
        icon: Icons.air,
        color: Palette.moss,
      );
    }
    if (indoorTemperature > 82 && weather.temperature < indoorTemperature) {
      return const AirflowAdvice(
        title: 'Brief ventilation may help',
        message: 'Outside is cooler than indoors. Open windows briefly if outdoor humidity stays low.',
        explanation: 'Cooler, drier outdoor air may improve comfort and reduce indoor moisture.',
        icon: Icons.device_thermostat,
        color: Palette.moss,
      );
    }
    return const AirflowAdvice(
      title: 'Keep monitoring',
      message: 'Conditions are stable. Check again later before changing ventilation.',
      explanation: 'There is no strong moisture advantage to opening or closing windows right now.',
      icon: Icons.monitor_heart_outlined,
      color: Palette.mist,
    );
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
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: advice.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(advice.icon, color: advice.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended now',
                    style: TextStyle(color: Palette.inkFaint, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    advice.title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: advice.color, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(advice.message, style: const TextStyle(color: Palette.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MascotCard extends StatelessWidget {
  const MascotCard({
    required this.mood,
    required this.message,
    super.key,
  });

  final MascotMood mood;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF496F5F),
            Color(0xFF6E9583),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Palette.mossDeep.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -55,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.055),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -70,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F1),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Moldling(
                    mood: mood,
                    size: 96,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'MOLD BUDDY',
                          style: TextStyle(
                            color: Color(0xFFDCEADF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.28,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class ConditionsCard extends StatelessWidget {
  const ConditionsCard({
    required this.title,
    required this.icon,
    required this.temperature,
    required this.humidity,
    required this.subtitle,
    this.accent = Palette.moss,
    super.key,
  });

  final String title;
  final IconData icon;
  final double temperature;
  final double humidity;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(
              '${temperature.round()}\u00b0F',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            Text('${humidity.round()}% humidity', style: const TextStyle(color: Palette.inkFaint)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Palette.inkFaint)),
          ],
        ),
      ),
    );
  }
}


class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Palette.softMint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 19,
            color: Palette.mossDeep,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Palette.inkFaint,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Palette.inkFaint))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
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
        Text('Humidity trends', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          '${controller.selectedRoom} \u2022 daily averages from the ESP32',
          style: const TextStyle(color: Palette.inkFaint),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: controller.selectedRoom,
          decoration: const InputDecoration(
            labelText: 'Room',
            prefixIcon: Icon(Icons.meeting_room_outlined),
          ),
          items: controller.rooms
              .map((room) => DropdownMenuItem(value: room, child: Text(room)))
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
                        style: TextStyle(color: Palette.inkFaint),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 6,
                        minY: 20,
                        maxY: 100,
                        clipData: const FlClipData.all(),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 10,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Palette.mossPale,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 38, interval: 20),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.round();
                                if (value != index.toDouble() || index < 0 || index >= data.length) {
                                  return const SizedBox.shrink();
                                }

                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_dayLabel(data[index].date), style: const TextStyle(fontSize: 11)),
                                      Text(
                                        _shortDate(data[index].date),
                                        style: const TextStyle(fontSize: 9, color: Palette.inkFaint),
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
                            color: Palette.mossDeep,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Palette.mossDeep.withValues(alpha: 0.10),
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
          color: Palette.mossPale,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.insights_outlined, color: Palette.mossDeep, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    improvement == null
                        ? 'More than one day of data is needed to calculate progress.'
                        : improvement > 0
                            ? 'Humidity improved by ${improvement.toStringAsFixed(1)} percentage points.'
                            : 'Humidity increased by ${(-improvement).toStringAsFixed(1)} percentage points.',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
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
          subtitle: best == null ? 'Connect the ESP32 to begin' : '${best.averageHumidity.toStringAsFixed(1)}% average humidity',
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

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _habitStorageKey(String habit) =>
      'habit_${_todayKey}_$habit';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in habits.keys) {
      habits[key] =
          prefs.getBool(_habitStorageKey(key)) ?? false;
    }

    if (mounted) setState(() {});
  }

  Future<void> _setHabit(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _habitStorageKey(key),
      value,
    );

    setState(() => habits[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final completed = habits.values.where((value) => value).length;
    final progress = completed / habits.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Text('Healthy-home habits', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Small actions can prevent bigger moisture problems.', style: TextStyle(color: Palette.inkFaint)),
        const SizedBox(height: 20),
        Card(
          color: Palette.mossPale,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white,
                  color: Palette.mossDeep,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '$completed of ${habits.length} habits completed today',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        for (final entry in habits.entries) ...[
          Card(
            child: CheckboxListTile(
              value: entry.value,
              onChanged: (value) => _setHabit(entry.key, value ?? false),
              title: Text(entry.key),
              activeColor: Palette.mossDeep,
              controlAffinity: ListTileControlAffinity.leading,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
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
        Text('Learn', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Simple explanations for common mold and moisture questions.', style: TextStyle(color: Palette.inkFaint)),
        const SizedBox(height: 20),
        const _HumidityGuide(),
        const SizedBox(height: 14),
        for (final topic in topics) ...[
          Card(
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
              collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
              leading: Icon(topic.$3, color: Palette.mossDeep),
              title: Text(topic.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [Align(alignment: Alignment.centerLeft, child: Text(topic.$2, style: const TextStyle(color: Palette.inkFaint)))],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}



class _HumidityGuide extends StatelessWidget {
  const _HumidityGuide();

  @override
  Widget build(BuildContext context) {
    const zones = [
      (
        'Under 50%',
        'Comfortable',
        'Keep checking for leaks and condensation.',
        Palette.moss,
      ),
      (
        '50–59%',
        'Keep watch',
        'Moisture is rising. Ventilation may help.',
        Palette.amber,
      ),
      (
        '60–69%',
        'Reduce moisture',
        'Try exhaust fans, drier outdoor air, or a dehumidifier.',
        Color(0xFFC36B34),
      ),
      (
        '70%+',
        'Take action',
        'Look for moisture sources and lower humidity promptly.',
        Palette.clay,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Palette.mossDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 9),
              Text(
                'Humidity cheat sheet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          for (final zone in zones)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: zone.$4,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 62,
                    child: Text(
                      zone.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFFDCEADF),
                          height: 1.25,
                        ),
                        children: [
                          TextSpan(
                            text: '${zone.$2} — ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: zone.$3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: TextButton.styleFrom(foregroundColor: Palette.inkFaint),
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
        Text('ESP32 device', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text(
          'Connect the monitor and choose which room it is measuring.',
          style: TextStyle(color: Palette.inkFaint),
        ),
        const SizedBox(height: 20),
        Card(
          color: controller.connected ? Palette.mossPale : const Color(0xFFFCF1DD),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  controller.connected ? Icons.check_circle : Icons.sensors_off_outlined,
                  color: controller.connected ? Palette.mossDeep : Palette.amber,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    controller.connected ? 'Connected \u2022 ${controller.selectedRoom}' : 'ESP32 is not connected',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
                const Text('Room being monitored', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedRoom,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.meeting_room_outlined)),
                  items: controller.rooms.map((room) => DropdownMenuItem(value: room, child: Text(room))).toList(),
                  onChanged: (room) {
                    if (room != null) controller.selectRoom(room);
                  },
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _addRoom,
                  style: TextButton.styleFrom(foregroundColor: Palette.mossDeep),
                  icon: const Icon(Icons.add),
                  label: const Text('Add another room'),
                ),
                const SizedBox(height: 14),
                const Text('Device IP address', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(hintText: '10.0.0.190'),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: Text(controller.connecting ? 'Connecting...' : 'Test connection'),
                  ),
                ),
                const SizedBox(height: 10),
                if (controller.connectionError != null)
                  Text(
                    controller.connectionError!,
                    style: const TextStyle(color: Palette.clay, fontSize: 12),
                  )
                else if (reading != null)
                  Text(
                    '${reading.temperatureF.toStringAsFixed(1)}\u00b0F \u2022 '
                    '${reading.humidity.toStringAsFixed(1)}% humidity \u2022 '
                    '${reading.pressureHpa.toStringAsFixed(1)} hPa',
                    style: const TextStyle(color: Palette.mossDeep, fontWeight: FontWeight.w700, fontSize: 12),
                  )
                else
                  const Text(
                    'Use the IP shown in Arduino Serial Monitor.',
                    style: TextStyle(color: Palette.inkFaint, fontSize: 12),
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
                Row(
                  children: [
                    const Icon(Icons.display_settings_outlined, color: Palette.mossDeep),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OLED display', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 3),
                          Text('Choose what the physical device shows.', style: TextStyle(color: Palette.inkFaint, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (controller.changingDisplayMode)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Palette.mossDeep),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final mode in DeviceDisplayMode.values) ...[
                  RadioListTile<DeviceDisplayMode>(
                    value: mode,
                    groupValue: controller.displayMode,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Palette.mossDeep,
                    secondary: Icon(mode.icon, color: Palette.mossDeep),
                    title: Text(mode.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(mode.subtitle),
                    onChanged: !controller.connected || controller.changingDisplayMode
                        ? null
                        : (value) {
                            if (value != null) {
                              controller.setDeviceDisplayMode(value);
                            }
                          },
                  ),
                  if (mode != DeviceDisplayMode.values.last) const Divider(height: 1),
                ],
                if (!controller.connected) ...[
                  const SizedBox(height: 8),
                  const Text('Connect the ESP32 before changing the OLED.', style: TextStyle(color: Palette.inkFaint, fontSize: 12)),
                ],
                if (controller.displayModeError != null) ...[
                  const SizedBox(height: 8),
                  Text(controller.displayModeError!, style: const TextStyle(color: Palette.clay, fontSize: 12)),
                ],
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
        InfoCard(
          title: 'OLED mode',
          value: controller.displayMode.title,
          subtitle: 'Saved and restored after reconnecting',
          icon: Icons.tv_outlined,
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
  const InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Palette.mossPale, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 22, color: Palette.mossDeep),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(color: Palette.inkFaint)),
          trailing: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}
