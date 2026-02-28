import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:async';
import 'dice_3d.dart';
import 'reward_service.dart';
import 'reward_dialog.dart';
import 'rule_page.dart';
import 'history_service.dart';
import 'history_page.dart';
import 'prediction_service.dart';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '骰子大赛',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // Default to "Start Rolling" (Middle)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const RulePage(),
          const DiceGamePage(),
          // Recreate HistoryPage when it's selected to force reload
          HistoryPage(key: ValueKey(_currentIndex == 2 ? 'history_active' : 'history_inactive')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: '中奖规则',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _currentIndex == 1 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.casino, size: 32),
            ),
            label: '开始投掷',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '历史记录',
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class DiceGamePage extends StatefulWidget {
  const DiceGamePage({super.key});

  @override
  State<DiceGamePage> createState() => _DiceGamePageState();
}

class _DiceGamePageState extends State<DiceGamePage> with TickerProviderStateMixin {
  // Use a list to store the values of 3 dice
  List<int> _diceValues = [1, 1, 1];
  List<int> _displayValues = [1, 1, 1]; // Values shown in UI
  bool _isRolling = false;
  
  // 0: Ready, 1: Rolled 1st, 2: Rolled 2nd, 3: Finished
  int _rollStep = 0; 
  List<PredictionResult> _predictions = [];
  
  final Random _random = Random();
  
  // Animation controllers for 3 dice
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  
  // Random start rotation for each die to make them look different
  final List<double> _startRotationX = [0, 0, 0];
  final List<double> _startRotationY = [0, 0, 0];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        // Custom bounce curve: EaseOut (throw) -> EaseIn (fall) -> BounceOut (land)
        curve: Curves.bounceOut, 
      );
    }).toList();

    _randomizeStartRotations();
  }

  void _randomizeStartRotations() {
    for (int i = 0; i < 3; i++) {
      _startRotationX[i] = _random.nextDouble() * 2 * pi;
      _startRotationY[i] = _random.nextDouble() * 2 * pi;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleRoll() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    if (_rollStep == 0) {
      // Step 0: Start new game, roll 1st die
      setState(() {
        // Generate new target values for all dice
        for (int i = 0; i < 3; i++) {
          _diceValues[i] = _random.nextInt(6) + 1;
        }
        _randomizeStartRotations();
        
        // Reset display values (hide 2nd and 3rd die initially or show as '?')
        // We keep previous values until they are rolled? Or reset to 1?
        // Let's keep them as is but maybe dim them? For now, just keep previous.
      });

      _controllers[0].reset();
      _controllers[0].forward().then((_) {
        setState(() {
          _isRolling = false;
          _rollStep = 1;
          _displayValues[0] = _diceValues[0];
          // Calculate predictions for next 2 dice
          _predictions = PredictionService.getTopPredictions(_diceValues, 1);
        });
      });
      
    } else if (_rollStep == 1) {
      // Step 1: Roll 2nd die
      _controllers[1].reset();
      _controllers[1].forward().then((_) {
        setState(() {
          _isRolling = false;
          _rollStep = 2;
          _displayValues[1] = _diceValues[1];
          // Calculate predictions for last die
          _predictions = PredictionService.getTopPredictions(_diceValues, 2);
        });
      });
      
    } else if (_rollStep == 2) {
      // Step 2: Roll 3rd die and finish
      _controllers[2].reset();
      _controllers[2].forward().then((_) {
        setState(() {
          _isRolling = false;
          _rollStep = 3;
          _displayValues[2] = _diceValues[2];
          _predictions = []; // Clear predictions
        });
        _checkAndShowReward();
      });
    } else {
      // Reset
      setState(() {
        _rollStep = 0;
        _predictions = [];
      });
      // Start immediately? Or wait for user to click again?
      // User clicked "Start Rolling", so we start rolling first die
      _handleRoll();
    }
  }

  void _checkAndShowReward() {
    final reward = RewardService.calculateReward(_diceValues);
    
    // Save history
    HistoryService.saveRecord(reward);

    // Always show dialog (even for no reward)
    // Use a slight delay to let the user see the dice result first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      // Ensure we are not in the middle of a device update (fix for mouse tracker assertion)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button to dismiss
          builder: (context) => RewardDialog(
            reward: reward,
            onDismiss: () {
              Navigator.of(context).pop();
              // Reset game state when dialog is dismissed
              setState(() {
                _rollStep = 0;
                _predictions = [];
              });
            },
          ),
        );
      });
      // Force a frame to ensure the callback runs even if the UI is static
      SchedulerBinding.instance.ensureVisualUpdate();
    });
  }

  String _getButtonText() {
    if (_isRolling) return '投掷中...';
    switch (_rollStep) {
      case 0: return '开始投掷';
      case 1: return '投掷第 2 个';
      case 2: return '投掷第 3 个';
      case 3: return '查看结果'; // Should not be visible usually as dialog pops up
      default: return '开始投掷';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show sum when all dice are rolled
    int totalSum = _displayValues.reduce((a, b) => a + b);
    bool showSum = _rollStep == 3 && !_isRolling;

    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Better contrast for 3D
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('骰子大赛'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 40),
                    const Text(
                      '准备好投掷了吗？',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    // Display 3 dice in a Row
                    SizedBox(
                      height: 120, // Reduced height
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDie(0),
                          _buildDie(1),
                          _buildDie(2),
                        ],
                      ),
                    ),
                    
                    // Prediction Widget
                    if (_predictions.isNotEmpty && !_isRolling)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🔥 推荐方案 (接下来投出):',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._predictions.map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  // Needed dice
                                  ...p.neededDice.map((v) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$v',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  const Icon(Icons.arrow_right_alt, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${p.description} (¥${p.potentialReward.toStringAsFixed(0)})',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 10),
                    // Show total sum only when finished
                    SizedBox(
                      height: 40,
                      child: AnimatedOpacity(
                        opacity: showSum ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '总分: $totalSum',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    // Add extra space at the bottom to ensure content isn't covered by the fixed button
                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ),
          ),
          // Fixed Bottom Button Area
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRolling ? null : _handleRoll,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 22),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_getButtonText()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDie(int index) {
    // Opacity logic:
    // If step > index, die is rolled and visible.
    // If step == index, die is waiting to be rolled (or rolling).
    // If step < index, die is future.
    // We can dim future dice.
    
    bool isRolled = _rollStep > index;
    bool isRolling = _isRolling && _rollStep == index;
    bool isFuture = _rollStep < index;
    
    return Opacity(
      opacity: isFuture ? 0.3 : 1.0,
      child: Dice3D(
        size: 80,
        animation: _animations[index],
        targetValue: isRolled || isRolling ? _diceValues[index] : 1, // Show 1 or actual value
        initialRotationX: _startRotationX[index],
        initialRotationY: _startRotationY[index],
      ),
    );
  }
}
