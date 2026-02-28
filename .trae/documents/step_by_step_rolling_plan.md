# Plan: Implement Step-by-Step Dice Rolling with Predictions

This plan aims to refactor the dice rolling mechanism from a simultaneous roll to a step-by-step process (one by one) to increase tension. Additionally, it will introduce a prediction system that recommends the best next rolls based on the current state.

## 1. Create Prediction Service

Create a new file `lib/prediction_service.dart` to handle the logic for calculating the best next moves.

- **Class**: `PredictionService`
- **Method**: `static List<PredictionResult> getTopPredictions(List<int> currentDice, int lockedCount)`
    - **Input**:
        - `currentDice`: The list of dice values (e.g., `[6, 1, 1]`).
        - `lockedCount`: How many dice are already rolled and fixed (e.g., 1 or 2).
    - **Logic**:
        - Iterate through all possible combinations for the remaining dice (6^2 for 1 locked, 6^1 for 2 locked).
        - Construct a temporary dice list for each combination.
        - Calculate the reward using `RewardService.calculateReward`.
        - Sort combinations by reward amount (descending).
        - Return the top 3 unique combinations.
- **Model**: `PredictionResult`
    - `double potentialReward`
    - `String rewardType`
    - `List<int> neededDice` (The values needed for the remaining dice)

## 2. Refactor `DiceGamePage` in `lib/main.dart`

Modify the `_DiceGamePageState` to manage the step-by-step rolling state.

- **State Variables**:
    - `int _rollStep = 0`: Tracks the current progress (0: Ready, 1: Die 1 rolled, 2: Die 2 rolled, 3: All rolled/Finished).
    - `List<PredictionResult> _predictions = []`: Stores the current recommendations.
    - Update `_displayValues` logic to support partial revealing (e.g., show Die 1, hide Die 2 & 3).

- **Logic Changes**:
    - **`_rollDice` (Rename to `_handleRoll`)**:
        - **Step 0 (Start)**:
            - Reset `_diceValues` and `_displayValues` (to 0 or hidden state).
            - Generate random values for all 3 dice (target values).
            - Trigger animation for **Die 1**.
            - On animation complete: Update `_rollStep = 1`, Reveal Die 1 value, Calculate & Show Predictions for next 2 dice.
        - **Step 1 (Continue)**:
            - Trigger animation for **Die 2**.
            - On animation complete: Update `_rollStep = 2`, Reveal Die 2 value, Calculate & Show Predictions for last die.
        - **Step 2 (Finish)**:
            - Trigger animation for **Die 3**.
            - On animation complete: Update `_rollStep = 3`, Reveal Die 3 value, Clear Predictions, Call `_checkAndShowReward`.
        - **Step 3 (Reset)**:
            - Reset to Step 0 state when starting a new game.

- **UI Changes**:
    - **Dice Display**:
        - Update `Dice3D` or its container to visually distinguish between "Rolled" (value visible), "Rolling" (animating), and "Waiting" (static/placeholder).
    - **Button**:
        - Change text dynamically: "开始投掷" -> "投掷第2个" -> "投掷第3个".
    - **Prediction Widget**:
        - Add a new widget (e.g., below the dice or above the button) to display `_predictions`.
        - Show "推荐方案: ..." with the needed dice values and potential reward.
        - Only visible when `_rollStep` is 1 or 2.

## 3. Verify and Test

- Verify that dice roll one by one.
- Verify that predictions are accurate based on the first 1 or 2 dice.
- Verify that the final result dialog still works and history is saved correctly.
- Ensure the game can be restarted correctly after finishing.
