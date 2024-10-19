import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:home_widget/home_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _showingResponse = false;
  String _fullResponse = "";
  int _responseIndex = 0;
  String _loadingText = "Hmm";
  Timer? _loadingTimer;
  bool _statsVisible = false;

  // Add new variables for stats
  Map<String, double> _stats = {};
  String _avatarImageUrl = 'assets/1.gif'; // Default avatar

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Fetch stats when the app initializes
    _fetchStats();
    _updateWidget();
  }

  // New method to fetch stats
  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('https://daily-journal-be.onrender.com/api/stats'));
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
          // Update avatar image URL based on the number returned by the API
          if (jsonResponse['image'] != null) {
            int imageNumber = jsonResponse['image'] as int;
            _avatarImageUrl = 'assets/$imageNumber.gif';
          } else {
            _avatarImageUrl = 'assets/1.gif'; // Default image
          }
        });
        _updateWidget();
      } else {
        print('Failed to load stats: ${response.statusCode}');
        _setDefaultStats();
      }
    } catch (e) {
      print('Error fetching stats: $e');
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
    _stopLoadingAnimation();
    _animationController.dispose();
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
          resizeToAvoidBottomInset: true, // Add this line
          body: Stack(
            
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/background.jpg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Spacer(),
                                          Image.network(
                                            _avatarImageUrl,
                                            width: 500,
                                            height: 300,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                _avatarImageUrl,
                                                width: 300,
                                                height: 300,
                                                fit: BoxFit.contain,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      // child: Column(
                      //   mainAxisAlignment: MainAxisAlignment.end,
                      //   children: [
                      //     Image.network(
                      //       _avatarImageUrl,
                      //       width: 500,
                      //       height: 300,
                      //       fit: BoxFit.contain,
                      //       errorBuilder: (context, error, stackTrace) {
                      //         return Image.asset(_avatarImageUrl, width: 300, height: 300, fit: BoxFit.contain);
                      //       },
                      //     ),
                      //   ],
                      // ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView( // Wrap with SingleChildScrollView
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.all(10),
                            child: _selectedOption.isEmpty
                                ? _buildOptionsList()
                                : _buildInputArea(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_statsVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.5, // Cover the first container
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _statsVisible = false;
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.8),
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildStatsSection(),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: MediaQuery.of(context).size.height * 0.25,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _statsVisible = !_statsVisible;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      _statsVisible ? ">" : "<",
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          _showingResponse
              ? Text(
                  _responseText.isEmpty ? _loadingText : _responseText,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              : TextField(
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
      });

      _startLoadingAnimation();

      try {
        late http.Response response;
        
        if (_selectedOption == "Enter Daily Journal") {
          response = await http.post(
            Uri.parse('https://daily-journal-be.onrender.com/api/daily-entry'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'date': DateTime.now().toIso8601String().split('T')[0],
              'entry': _inputController.text,
            }),
          );
        } else if (_selectedOption == "Ask a Question") {
          response = await http.post(
            Uri.parse('https://daily-journal-be.onrender.com/api/ask'),
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
              });
              _updateWidget();
            }
            if (jsonResponse['image'] != null) {
              setState(() {
                _avatarImageUrl = 'assets/${jsonResponse['image']}.gif';
              });
            }
          } else if (_selectedOption == "Ask a Question") {
            _fullResponse = jsonResponse['answer'];
          }
          _responseIndex = 0;
          _typeResponse();
        } else {
          _fullResponse = "Error: ${response.statusCode}";
          _responseIndex = 0;
          _typeResponse();
        }
      } catch (e) {
        _stopLoadingAnimation();
        _fullResponse = "Error: $e";
        _responseIndex = 0;
        _typeResponse();
      }

      _inputController.clear();
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
      });
      Future.delayed(Duration(milliseconds: 50), _typeResponse);
    } else {
      Future.delayed(Duration(seconds: 2), () { // Changed to 2 seconds
        setState(() {
          _showingResponse = false;
          _responseText = "";
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
        return Color(0xFF6A5ACD);
      case 'Wisdom':
        return Color(0xFFFFA500);
      case 'Charisma':
        return Color(0xFF008080);
      case 'Skill':
        return Color(0xFF4B0082);
      default:
        return Colors.grey;
    }
  }

  void _updateWidget() {
    print('Updating widget with stats: ${_stats['Health']}');
    HomeWidget.saveWidgetData<String>('health', 'Health: ${((_stats['Health'] ?? 0.0) * 100).toInt()}');
    HomeWidget.saveWidgetData<String>('energy', 'Energy: ${((_stats['Energy'] ?? 0.0) * 100).toInt()}');
    HomeWidget.saveWidgetData<String>('mental', 'Mental: ${((_stats['Mental'] ?? 0.0) * 100).toInt()}');
    HomeWidget.saveWidgetData<String>('wisdom', 'Wisdom: ${((_stats['Wisdom'] ?? 0.0) * 100).toInt()}');
    HomeWidget.saveWidgetData<String>('skill', 'Skill: ${((_stats['Skill'] ?? 0.0) * 100).toInt()}');
    
    HomeWidget.updateWidget(
      name: 'HomeWidgetProvider',
      androidName: 'HomeWidgetProvider',
      iOSName: 'HomeWidgetProvider',
    );
  }
}
