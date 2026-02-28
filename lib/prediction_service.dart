import 'reward_service.dart';

class PredictionResult {
  final double potentialReward;
  final String rewardType;
  final String description;
  final List<int> neededDice;

  PredictionResult({
    required this.potentialReward,
    required this.rewardType,
    required this.description,
    required this.neededDice,
  });
}

class PredictionService {
  /// Get top 3 predictions for the remaining dice
  /// [currentDice] contains all 3 dice, but only the first [lockedCount] are fixed.
  static List<PredictionResult> getTopPredictions(List<int> currentDice, int lockedCount) {
    if (lockedCount >= 3) return [];

    List<PredictionResult> allPredictions = [];
    int diceToRoll = 3 - lockedCount;

    if (diceToRoll == 2) {
      // Iterate through all combinations for 2 dice (6 * 6 = 36)
      for (int d1 = 1; d1 <= 6; d1++) {
        for (int d2 = 1; d2 <= 6; d2++) {
          List<int> testDice = List.from(currentDice);
          testDice[1] = d1;
          testDice[2] = d2;
          
          final reward = RewardService.calculateReward(testDice);
          if (reward.amount > 0) {
            allPredictions.add(PredictionResult(
              potentialReward: reward.amount,
              rewardType: reward.rewardType,
              description: reward.description,
              neededDice: [d1, d2],
            ));
          }
        }
      }
    } else if (diceToRoll == 1) {
      // Iterate through all combinations for 1 die (6)
      for (int d1 = 1; d1 <= 6; d1++) {
        List<int> testDice = List.from(currentDice);
        testDice[2] = d1;
        
        final reward = RewardService.calculateReward(testDice);
        if (reward.amount > 0) {
          allPredictions.add(PredictionResult(
            potentialReward: reward.amount,
            rewardType: reward.rewardType,
            description: reward.description,
            neededDice: [d1],
          ));
        }
      }
    }

    // Sort by reward amount descending
    allPredictions.sort((a, b) => b.potentialReward.compareTo(a.potentialReward));
    
    // Deduplicate: If multiple combinations yield the same reward type and amount, keep unique sorted needed dice
    final uniquePredictions = <String, PredictionResult>{};
    for (var p in allPredictions) {
      // Key based on sorted needed dice + reward type + amount
      final sortedNeeded = List<int>.from(p.neededDice)..sort();
      final key = '${p.rewardType}_${p.potentialReward}_${sortedNeeded.join(',')}';
      
      if (!uniquePredictions.containsKey(key)) {
        uniquePredictions[key] = p;
      }
    }
    
    // Convert map values to list and sort again just to be safe (map iteration order is insertion order in Dart, so it should be fine)
    final result = uniquePredictions.values.toList();
    // No need to sort again as insertion was in sorted order
    
    return result.take(5).toList();
  }
}
