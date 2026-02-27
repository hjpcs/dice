import 'package:flutter_test/flutter_test.dart';
import 'package:dice/reward_service.dart';

void main() {
  group('RewardService Tests', () {
    // 1. 豹子 (5200)
    test('Leopard returns 5200', () {
      expect(RewardService.calculateReward([1, 1, 1]).amount, 5200);
      expect(RewardService.calculateReward([6, 6, 6]).amount, 5200);
    });

    // 2. Sum >= 15 (1314)
    test('Sum >= 15 returns 1314', () {
      expect(RewardService.calculateReward([5, 5, 6]).amount, 1314); // 16
      expect(RewardService.calculateReward([4, 5, 6]).amount, 1314); // 15
      expect(RewardService.calculateReward([6, 6, 5]).amount, 1314); // 17
    });

    // 3. Sum <= 6 (1314)
    test('Sum <= 6 returns 1314', () {
      expect(RewardService.calculateReward([1, 2, 3]).amount, 1314); // 6
      expect(RewardService.calculateReward([1, 1, 2]).amount, 1314); // 4
      expect(RewardService.calculateReward([1, 2, 2]).amount, 1314); // 5
    });

    // 4. Sum >= 12 (520)
    test('Sum >= 12 returns 520', () {
      expect(RewardService.calculateReward([3, 4, 5]).amount, 520); // 12
      expect(RewardService.calculateReward([4, 4, 5]).amount, 520); // 13
      expect(RewardService.calculateReward([2, 6, 6]).amount, 520); // 14
    });

    // 5. Sum <= 9 (520)
    test('Sum <= 9 returns 520', () {
      expect(RewardService.calculateReward([2, 3, 4]).amount, 520); // 9
      expect(RewardService.calculateReward([1, 3, 4]).amount, 520); // 8
      expect(RewardService.calculateReward([2, 2, 3]).amount, 520); // 7
    });

    // 6. Pair (131.4)
    test('Pair returns 131.4', () {
      expect(RewardService.calculateReward([2, 2, 6]).amount, 131.4); // 10
      expect(RewardService.calculateReward([3, 3, 5]).amount, 131.4); // 11
      expect(RewardService.calculateReward([5, 5, 1]).amount, 131.4); // 11
    });

    // 7. No Reward
    test('No match returns 0', () {
      expect(RewardService.calculateReward([1, 4, 5]).amount, 0); // 10, no pair
      expect(RewardService.calculateReward([2, 3, 6]).amount, 0); // 11, no pair
    });

    // Priority Check
    test('Leopard has highest priority over Sum <= 6', () {
      // [1, 1, 1] sum is 3 (<=6), but should be Leopard
      expect(RewardService.calculateReward([1, 1, 1]).rewardType, 'LEOPARD');
      expect(RewardService.calculateReward([1, 1, 1]).amount, 5200);
    });

    test('Sum <= 6 has priority over Pair', () {
      // [1, 1, 2] sum is 4 (<=6), also has Pair. Should be Sum <= 6
      expect(RewardService.calculateReward([1, 1, 2]).rewardType, 'SMALL_EXTREME');
      expect(RewardService.calculateReward([1, 1, 2]).amount, 1314);
    });
  });
}
