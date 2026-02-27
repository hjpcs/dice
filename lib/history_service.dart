import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'reward_service.dart';

class HistoryItem {
  final int timestamp;
  final List<int> diceValues;
  final double amount;
  final String description;
  final String rewardType;

  HistoryItem({
    required this.timestamp,
    required this.diceValues,
    required this.amount,
    required this.description,
    required this.rewardType,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'diceValues': diceValues,
      'amount': amount,
      'description': description,
      'rewardType': rewardType,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      timestamp: json['timestamp'],
      diceValues: List<int>.from(json['diceValues']),
      amount: json['amount'],
      description: json['description'],
      rewardType: json['rewardType'],
    );
  }
}

class HistoryService {
  static const String _keyHistory = 'dice_history';

  static Future<void> saveRecord(RewardResult result) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create new item
    final newItem = HistoryItem(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      diceValues: result.diceValues,
      amount: result.amount,
      description: result.description,
      rewardType: result.rewardType,
    );

    // Get existing history
    List<HistoryItem> history = await getHistory();
    
    // Add new item to the beginning
    history.insert(0, newItem);
    
    // Limit history size (e.g., keep last 100 records)
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }

    // Save back to prefs
    final String jsonString = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistory, jsonString);
  }

  static Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyHistory);
    
    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => HistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}
