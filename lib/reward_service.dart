class RewardResult {
  final double amount;
  final String description;
  final String rewardType; // 'LEOPARD', 'BIG', 'SMALL', 'PAIR', 'NONE'
  final List<int> diceValues;

  RewardResult({
    required this.amount,
    required this.description,
    required this.rewardType,
    required this.diceValues,
  });
}

class RewardService {
  static RewardResult calculateReward(List<int> diceValues) {
    if (diceValues.length != 3) {
      return RewardResult(
        amount: 0,
        description: '无效投掷',
        rewardType: 'NONE',
        diceValues: [],
      );
    }

    int sum = diceValues.reduce((a, b) => a + b);
    
    // Sort dice for easier pair checking
    List<int> sorted = List.from(diceValues)..sort();

    // 1. Check for Leopard (豹子) - All same
    if (sorted[0] == sorted[1] && sorted[1] == sorted[2]) {
      return RewardResult(
        amount: 5200,
        description: '豹子！大吉大利！',
        rewardType: 'LEOPARD',
        diceValues: List.from(diceValues),
      );
    }

    // 2. Check for Sum >= 15 (Large Sum)
    if (sum >= 15) {
      return RewardResult(
        amount: 1314,
        description: '点数和 $sum (≥15)',
        rewardType: 'BIG_EXTREME',
        diceValues: List.from(diceValues),
      );
    }

    // 3. Check for Sum <= 6 (Small Sum)
    if (sum <= 6) {
      return RewardResult(
        amount: 1314,
        description: '点数和 $sum (≤6)',
        rewardType: 'SMALL_EXTREME',
        diceValues: List.from(diceValues),
      );
    }

    // 4. Check for Sum >= 12 (Medium Large Sum)
    if (sum >= 12) {
      return RewardResult(
        amount: 520,
        description: '点数和 $sum (≥12)',
        rewardType: 'BIG',
        diceValues: List.from(diceValues),
      );
    }

    // 5. Check for Sum <= 9 (Medium Small Sum)
    if (sum <= 9) {
      return RewardResult(
        amount: 520,
        description: '点数和 $sum (≤9)',
        rewardType: 'SMALL',
        diceValues: List.from(diceValues),
      );
    }

    // 6. Check for Pair (有一对)
    // Since sorted: [a, a, b] or [a, b, b]
    if (sorted[0] == sorted[1] || sorted[1] == sorted[2]) {
      return RewardResult(
        amount: 131.4,
        description: '对子成双',
        rewardType: 'PAIR',
        diceValues: List.from(diceValues),
      );
    }

    // No reward
    return RewardResult(
      amount: 0,
      description: '再接再厉',
      rewardType: 'NONE',
      diceValues: List.from(diceValues),
    );
  }
}
