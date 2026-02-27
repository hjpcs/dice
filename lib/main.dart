import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:async';
import 'dice_3d.dart';
import 'reward_service.dart';
import 'reward_dialog.dart';
import 'rule_dialog.dart';
import 'history_service.dart';
import 'history_page.dart';

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
      home: const DicePage(title: '骰子大赛'),
    );
  }
}

class DicePage extends StatefulWidget {
  const DicePage({super.key, required this.title});

  final String title;

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> with TickerProviderStateMixin {
  // Use a list to store the values of 3 dice
  List<int> _diceValues = [1, 1, 1];
  List<int> _displayValues = [1, 1, 1]; // Values shown in UI
  bool _isRolling = false;
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

  void _rollDice() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
      // Generate new target values immediately, but they will be reached at the end of animation
      for (int i = 0; i < 3; i++) {
        _diceValues[i] = _random.nextInt(6) + 1;
      }
      _randomizeStartRotations();
    });

    // Reset and start animations with slight stagger
    for (int i = 0; i < 3; i++) {
      _controllers[i].reset();
      Future.delayed(Duration(milliseconds: i * 150), () {
        _controllers[i].forward().then((_) {
          // When the last animation finishes
          if (i == 2) {
            setState(() {
              _isRolling = false;
              // Update display values only after animation completes
              _displayValues = List.from(_diceValues);
            });
            _checkAndShowReward();
          }
        });
      });
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
            },
          ),
        );
      });
      // Force a frame to ensure the callback runs even if the UI is static
      SchedulerBinding.instance.ensureVisualUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalSum = _displayValues.reduce((a, b) => a + b);

    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Better contrast for 3D
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const RuleDialog(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            tooltip: '历史记录',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '准备好投掷了吗？',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),
            // Display 3 dice in a Row
            SizedBox(
              height: 200, // Enough space for bounce animation
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Dice3D(
                    size: 80,
                    animation: _animations[0],
                    targetValue: _diceValues[0],
                    initialRotationX: _startRotationX[0],
                    initialRotationY: _startRotationY[0],
                  ),
                  Dice3D(
                    size: 80,
                    animation: _animations[1],
                    targetValue: _diceValues[1],
                    initialRotationX: _startRotationX[1],
                    initialRotationY: _startRotationY[1],
                  ),
                  Dice3D(
                    size: 80,
                    animation: _animations[2],
                    targetValue: _diceValues[2],
                    initialRotationX: _startRotationX[2],
                    initialRotationY: _startRotationY[2],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Show total sum only when not rolling
            SizedBox(
              height: 50,
              child: AnimatedOpacity(
                opacity: _isRolling ? 0.0 : 1.0,
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
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isRolling ? null : _rollDice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 22),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 5,
              ),
              child: Text(_isRolling ? '投掷中...' : '开始投掷'),
            ),
          ],
        ),
      ),
    );
  }
}
