import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print("Initializing NotificationService");
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        print("Notification received: ${details.payload}");
      },
    );
    print("NotificationService initialized");
    await AndroidAlarmManager.initialize();
    _scheduleDaily11PMAlarm();
  }

  void _scheduleDaily11PMAlarm() {
    AndroidAlarmManager.periodic(
      const Duration(days: 1),
      0, // Unique ID for this alarm
      _showNotification,
      startAt: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 0),
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _showNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_journal_channel',
      'Daily Journal Notifications',
      channelDescription: 'Notifications for daily journal reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      'Daily Journal Reminder',
      'It\'s time to write your journal entry!',
      platformChannelSpecifics,
    );
    print('Notification sent at ${DateTime.now()}');
  }

  // For testing purposes
  Future<void> showTestNotification() async {
    await _showNotification();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      debugShowCheckedModeBanner: false,  // Add this line
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black.withOpacity(0.7), // Almost black background
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'PressStart2P',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _responseText = "";
  String _selectedOption = "";
  String _blinkingOption = "Enter Daily Journal";
  TextEditingController _inputController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showingResponse = false;
  String _fullResponse = "";
  int _responseIndex = 0;
  String _loadingText = "Hmm";
  Timer? _loadingTimer;
  bool _statsVisible = false;

  // Add new variables for stats
  Map<String, double> _stats = {};
  String _avatarImageUrl = 'assets/1.gif'; // Default avatar
  int _currentCarouselIndex = 0;
  int _waterCount = 0;
  int _cigaretteCount = 0;
  int _lastResetTimestamp = 0;
  int _pornStreak = 0;
  int _workoutStreak = 0;
  int _currentBackgroundIndex = 1;
  bool _showWelcomeMessage = true;
  String _welcomeText = "";
  int _welcomeIndex = 0;
  final String _fullWelcomeText = "Welcome to your Daily Journal";
  String _optionWelcomeText = "";
  int _optionWelcomeIndex = 0;
  bool _showOptionWelcome = false;
  bool _isShowingMessage = false; // Add this line

  @override
  void initState() {
    super.initState();
    _loadCounters();
    _loadStatsLocally();
    _fetchStats();
    NotificationService().init();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.repeat(reverse: true);

    // Start typing the welcome message
    _typeWelcomeMessage();
    _updateStreaksDaily();
  }


  void _loadCounters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterCount = prefs.getInt('waterCount') ?? 0;
      _cigaretteCount = prefs.getInt('cigaretteCount') ?? 0;
      _lastResetTimestamp = prefs.getInt('lastResetTimestamp') ?? 0;
    });
    _resetCountersIfNewDay();
  }

  void _saveCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waterCount', _waterCount);
    await prefs.setInt('cigaretteCount', _cigaretteCount);
    await prefs.setInt('lastResetTimestamp', _lastResetTimestamp);
  }

  void _resetCountersIfNewDay() {
    final now = DateTime.now();
    final lastReset = DateTime.fromMillisecondsSinceEpoch(_lastResetTimestamp);
    if (now.day != lastReset.day || now.month != lastReset.month || now.year != lastReset.year) {
      setState(() {
        _waterCount = 0;
        _cigaretteCount = 0;
        _lastResetTimestamp = now.millisecondsSinceEpoch;
      });
      _saveCounters();
    }
  }

  // New method to fetch stats
  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('https://daily-journal-be-1.onrender.com/api/stats'));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        setState(() {
          _stats = {
            'Health': _parseStatValue(jsonResponse['health']),
            'Energy': _parseStatValue(jsonResponse['energy']),
            'Mental': _parseStatValue(jsonResponse['mental']),
            'Wisdom': _parseStatValue(jsonResponse['intellect']),
            'Skill': _parseStatValue(jsonResponse['skill']),
          };
          // print(jsonResponse['porn_streak']);
          // _pornStreak = jsonResponse['porn_streak'] ?? 0;
          // _workoutStreak = jsonResponse['workout_streak'] ?? 0;
          
          if (jsonResponse['image'] != null) {
            int imageNumber = jsonResponse['image'] as int;
            _avatarImageUrl = 'assets/$imageNumber.gif';
          } else {
            _avatarImageUrl = 'assets/1.gif'; // Default image
          }
        });
        
        // Save to local storage
        _saveStatsLocally();
      } else {
        print('Failed to load stats: ${response.statusCode}');
        _loadStatsLocally();
      }
    } catch (e) {
      print('Error fetching stats: $e');
      _loadStatsLocally();
    }
  }

  void _saveStatsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pornStreak', _pornStreak);
    await prefs.setInt('workoutStreak', _workoutStreak);
    await prefs.setString('stats', jsonEncode(_stats));
    await prefs.setString('avatarImageUrl', _avatarImageUrl);
    await prefs.setInt('currentBackgroundIndex', _currentBackgroundIndex);
  }

  void _loadStatsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pornStreak = prefs.getInt('pornStreak') ?? 0;
      _workoutStreak = prefs.getInt('workoutStreak') ?? 0;
      _stats = Map<String, double>.from(jsonDecode(prefs.getString('stats') ?? '{}'));
      _avatarImageUrl = prefs.getString('avatarImageUrl') ?? 'assets/1.gif';
      _currentBackgroundIndex = prefs.getInt('currentBackgroundIndex') ?? 1;
    });
    if (_stats.isEmpty) {
      _setDefaultStats();
    }
  }

  double _parseStatValue(dynamic value) {
    if (value is int) {
      return value.toDouble() / 100;
    } else if (value is double) {
      return value / 100;
    } else if (value is String) {
      return double.tryParse(value)?.clamp(0.0, 100.0) ?? 0.0 / 100;
    } else {
      return 0.0;
    }
  }

  void _setDefaultStats() {
    setState(() {
      _stats = {
        'Health': 0.5,
        'Energy': 0.5,
        'Mental': 0.5,
        'Intellect': 0.5,
        'Charisma': 0.5,
        'Skill': 0.5,
      };
      _avatarImageUrl = 'assets/1.gif';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopLoadingAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedOption.isNotEmpty) {
          setState(() {
            _selectedOption = "";
            _blinkingOption = "Enter Daily Journal";
            _inputController.clear();
          });
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onTap: () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                   minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: FlutterCarousel(
                        options: CarouselOptions(
                          height: double.infinity,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                          autoPlay: false,
                          enableInfiniteScroll: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          },
                        ),
                        items: [
                          _buildAvatarSlide(),
                          _buildCounterSlide(),
                          _buildStatsSlide(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: _showWelcomeMessage
                          ? _buildWelcomeMessage()
                          : (_selectedOption.isEmpty
                              ? _buildOptionsList()
                              : _buildInputArea()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSlide() {
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _currentBackgroundIndex = (_currentBackgroundIndex % 5) + 1;
        });
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background$_currentBackgroundIndex.gif'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              _showingResponse && _responseText.isEmpty
                ? 'assets/4.gif'
                : (_isShowingMessage ? 'assets/5.gif' : _avatarImageUrl),
               width: 800,
              height: 300,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSlide() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: _buildStatsSection(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _stats.entries.map((entry) {
        return Column(
          children: [
            _buildStatBar(entry.key, entry.value, _getColorForStat(entry.key)),
            SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 25,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(
                    color: Colors.grey[800],
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      color: color,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(value * 100).toInt()}',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsList() {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildOptionItem("Enter Daily Journal", "Tell me about your day..."),
            SizedBox(height: 8),
            _buildOptionItem("Ask a Question", "Ask me Anything..."),
            SizedBox(height: 8),
            _buildOptionItem("Enter Personal Details", "Tell me something about yourself..."),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(String title, String placeholder) {
    bool isBlinking = _blinkingOption == title;
    bool isSelected = _selectedOption == title;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (isBlinking) {
              setState(() {
                _selectedOption = title;
                _blinkingOption = "";
                _inputController.clear();
              });
              // Add welcome message for each option
              switch (title) {
                case "Enter Daily Journal":
                  _typeOptionWelcome("What's up? How was your day?");
                  break;
                case "Ask a Question":
                  _typeOptionWelcome("What's on your mind?");
                  break;
                case "Enter Personal Details":
                  _typeOptionWelcome("Let me get to know you better");
                  break;
              }
            } else {
              setState(() {
                _blinkingOption = _blinkingOption == title ? "" : title;
                if (_blinkingOption.isEmpty) {
                  _selectedOption = "";
                }
              });
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBlinking || isSelected ? ">" : " ",
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 16,
                    color: isBlinking
                        ? _animationController.value > 0.5 ? Colors.red : Colors.white
                        : isSelected ? Colors.red : Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 18,
                      color: isBlinking
                          ? _animationController.value > 0.5 ? Colors.red : Colors.white
                          : isSelected ? Colors.red : Colors.white,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    String placeholder = "";
    switch (_selectedOption) {
      case "Enter Daily Journal":
        placeholder = "Tell me about your day...";
        break;
      case "Ask a Question":
        placeholder = "Ask me Anything...";
        break;
      case "Enter Personal Details":
        placeholder = "Tell me something about yourself...";
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showOptionWelcome)
            Text(
              _optionWelcomeText,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 18,
                color: Colors.white,
              ),
            )
          else if (_showingResponse)
            Text(
              _responseText.isEmpty ? _loadingText : _responseText,
              style: TextStyle(fontSize: 16, color: Colors.white),
            )
          else
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(fontFamily: 'PressStart2P', fontSize: 16, color: Colors.white70),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              ),
              style: TextStyle(fontSize: 16, color: Colors.white),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send, // Change this to send
              onSubmitted: (_) => _sendToApi(), // Add this line
            ),
        ],
      ),
    );
  }

  void _sendToApi() async {
    if (_inputController.text.isNotEmpty) {
      setState(() {
        _showingResponse = true;
        _loadingText = "Hmm"; // Set initial state
        _isShowingMessage = false; // Show loading GIF
      });
 
      _startLoadingAnimation();
 
      try {
        late http.Response response;
        
        if (_selectedOption == "Enter Daily Journal") {
          response = await http.post(
            Uri.parse('https://daily-journal-be-1.onrender.com/api/daily-entry'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, dynamic>{
              'date': DateTime.now().toIso8601String().split('T')[0],
              'entry': _inputController.text,
              'water': _waterCount,
              'smoke': _cigaretteCount,
              'porn_streak': _pornStreak,
              'workout_streak': _workoutStreak,
            }),
          );
        } else if (_selectedOption == "Ask a Question") {
          response = await http.post(
            Uri.parse('https://daily-journal-be-1.onrender.com/api/ask'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'entry': _inputController.text,
            }),
          );
        }
 
        _stopLoadingAnimation();
 
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          if (_selectedOption == "Enter Daily Journal") {
            _fullResponse = jsonResponse['message'];
            setState(() {
              _isShowingMessage = true; // Show message GIF
            });
            // Update stats and avatar image
            if (jsonResponse != null) {
              setState(() {
                _stats = {
                  'Health': _parseStatValue(jsonResponse['health']),
                  'Energy': _parseStatValue(jsonResponse['energy']),
                  'Mental': _parseStatValue(jsonResponse['mental']),
                  'Wisdom': _parseStatValue(jsonResponse['intellect']),
                  'Skill': _parseStatValue(jsonResponse['skill']),
                };
                // Update streaks if provided in the response
                // if (jsonResponse['porn_streak'] != null) {
                //   _pornStreak = jsonResponse['porn_streak'];
                // }
                // if (jsonResponse['workout_streak'] != null) {
                //   _workoutStreak = jsonResponse['workout_streak'];
                // }
              });
              print(_stats);
              _saveStatsLocally();  // Save updated stats and streaks
            }
            if (jsonResponse['image'] != null) {
              setState(() {
                _avatarImageUrl = 'assets/${jsonResponse['image']}.gif';
              });
              _saveStatsLocally();  // Save updated avatar image
            }
          } else if (_selectedOption == "Ask a Question") {
            _fullResponse = jsonResponse['answer'];
          }
          _responseIndex = 0;
          _typeResponse();
        } else {
          _fullResponse = "Error: ${response.statusCode}";
          _responseIndex = 0;
          setState(() {
            _isShowingMessage = true; // Show message GIF
          });
          _typeResponse();
        }
      } catch (e) {
        _stopLoadingAnimation();
        _fullResponse = "Error: $e";
        _responseIndex = 0;
        setState(() {
          _isShowingMessage = true; // Show message GIF
        });
        _typeResponse();
      }
 
      _inputController.clear();
    }
  }
 
  Future<void> _updateStreaksInDB() async {
    try {
      final response = await http.post(
        Uri.parse('https://daily-journal-be-1.onrender.com/api/update-streak'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'pornStreak': _pornStreak,
          'workoutStreak': _workoutStreak,
        }),
      );
 
      if (response.statusCode == 200) {
        print('Streaks updated successfully in DB');
      } else {
        print('Failed to update streaks in DB: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating streaks in DB: $e');
    }
  }

  void _startLoadingAnimation() {
    _loadingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        switch (_loadingText) {
          case "Hmm":
            _loadingText = "Hmm.";
            break;
          case "Hmm.":
            _loadingText = "Hmm..";
            break;
          case "Hmm..":
            _loadingText = "Hmm...";
            break;
          case "Hmm...":
            _loadingText = "Hmm";
            break;
          default:
            _loadingText = "Hmm";
        }
      });
    });
  }

  void _stopLoadingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    _loadingText = "Hmm"; // Reset to initial state
  }

  void _typeResponse() {
    if (_responseIndex < _fullResponse.length) {
      setState(() {
        _responseText = _fullResponse.substring(0, _responseIndex + 1);
        _responseIndex++;
        _isShowingMessage = true; // Show message GIF
      });
      Future.delayed(Duration(milliseconds: 50), _typeResponse);
    } else {
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _showingResponse = false;
          _responseText = "";
          _isShowingMessage = false; // Reset to default GIF
        });
      });
    }
  }

  // Helper method to get color for each stat
  Color _getColorForStat(String stat) {
    switch (stat) {
      case 'Health':
        return Color(0xFFDC143C);
      case 'Energy':
        return Color(0xFF3CB371);
      case 'Mental':
        return Colors.blue;
      case 'Wisdom':
        return Color(0xFFFFA500);
      case 'Charisma':
        return Color(0xFF008080);
      case 'Skill':
        return Color(0xFF6A5ACD);
      default:
        return Colors.grey;
    }
  }

  Widget _buildCounterSlide() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCounterButton(
                icon: Icons.no_adult_content,
                count: _pornStreak,
                onPressed: () {}, // Do nothing on press
                onLongPress: () => _updateStreak('porn', true), // Only reset on long press
                color: Colors.purple,
              ),
              _buildCounterButton(
                icon: Icons.fitness_center,
                count: _workoutStreak,
                onPressed: () => _updateStreak('workout', false), // Increment on normal press
                onLongPress: () => _updateStreak('workout', true), // Reset on long press
                color: Colors.yellow,
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCounterButton(
                icon: Icons.local_drink,
                count: _waterCount,
                onPressed: () {
                  setState(() {
                    _waterCount++;
                  });
                  _saveCounters();
                },
                onLongPress: () {
                  setState(() {
                    _waterCount = 0;
                  });
                  _saveCounters();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Water count reset to 0')),
                  );
                },
                color: Colors.blue,
              ),
              _buildCounterButton(
                icon: Icons.smoking_rooms,
                count: _cigaretteCount,
                onPressed: () {
                  setState(() {
                    _cigaretteCount++;
                  });
                  _saveCounters();
                },
                onLongPress: () {
                  setState(() {
                    _cigaretteCount = 0;
                  });
                  _saveCounters();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cigarette count reset to 0')),
                  );
                },
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required int count,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    required Color color,
  }) {
    return _AnimatedButton(
      child: Container(
        width: 100,
        height: 100,
        child: ElevatedButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 40,
                color: Colors.black,
              ),
              SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            padding: EdgeInsets.all(15),
            backgroundColor: color,
          ),
        ),
      ),
    );
  }

  void _updateStreak(String streakType, bool reset) {
    setState(() {
      if (reset) {
        if (streakType == 'porn') {
          _pornStreak = 0;
        } else if (streakType == 'workout') {
          _workoutStreak = 0;
        }
      } else {
        if (streakType == 'workout') {
          _updateWorkoutStreak();
        }
        // Porn streak is not incremented here anymore
      }
    });
    _saveStatsLocally();  // Save updated streak values locally
  
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$streakType streak ${reset ? "reset" : "updated"}')),
    );
  }

  Widget _buildWelcomeMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          _welcomeText,
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _typeWelcomeMessage() {
    setState(() {
      _isShowingMessage = true;
    });
    if (_welcomeIndex < _fullWelcomeText.length) {
      setState(() {
        _welcomeText = _fullWelcomeText.substring(0, _welcomeIndex + 1);
        _welcomeIndex++;
      });
      Future.delayed(Duration(milliseconds: 50), _typeWelcomeMessage);
    } else {
      Future.delayed(Duration(milliseconds: 1500), () {
        setState(() {
          _showWelcomeMessage = false;
          _isShowingMessage = false;
        });
      });
    }
  }

  void _typeOptionWelcome(String message) {
    _optionWelcomeText = "";
    _optionWelcomeIndex = 0;
    setState(() {
      _showOptionWelcome = true;
      _isShowingMessage = true;
    });
    
    void typeNextLetter() {
      if (_optionWelcomeIndex < message.length) {
        setState(() {
          _optionWelcomeText = message.substring(0, _optionWelcomeIndex + 1);
          _optionWelcomeIndex++;
        });
        Future.delayed(Duration(milliseconds: 50), typeNextLetter);
      } else {
        Future.delayed(Duration(milliseconds: 1500), () {
          setState(() {
            _showOptionWelcome = false;
            _isShowingMessage = false;
          });
        });
      }
    }
 
    typeNextLetter();
  }

  // Add this method to your _HomePageState class
  void _updateStreaksDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateDate = prefs.getString('lastStreakUpdate') ?? '';
    final today = DateTime.now().toIso8601String().split('T')[0];
 
    if (lastUpdateDate != today) {
      setState(() {
        _pornStreak++;  // Increment porn streak
        _workoutStreak = 0;  // Reset workout streak
      });
      await prefs.setString('lastStreakUpdate', today);
      await prefs.setString('lastWorkoutDate', '');  // Reset last workout date
      _saveStatsLocally();
    }
  }
 
  void _updateWorkoutStreak() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    SharedPreferences.getInstance().then((prefs) {
      final lastWorkoutDate = prefs.getString('lastWorkoutDate') ?? '';
      print (lastWorkoutDate);
      if (lastWorkoutDate != today) {
        setState(() {
          _workoutStreak++;
        });
        prefs.setString('lastWorkoutDate', today);
        _saveStatsLocally();
      }
    });
  }
}

class _AnimatedButton extends StatefulWidget {
  final Widget child;

  const _AnimatedButton({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

