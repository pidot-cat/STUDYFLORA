/// Coins for submitting a reviewer (once per unique file).
const int uploadReward = 10;

/// Quiz payout: 5 coins minimum, 100 for a perfect score.
/// Tiers match the approved mockups (100% -> +100, 80% -> +50).
int coinsForScore(int correct, int total) {
  if (total <= 0) return 5;
  final pct = correct * 100 / total;
  if (pct >= 100) return 100;
  if (pct >= 90) return 75;
  if (pct >= 80) return 50;
  if (pct >= 70) return 30;
  if (pct >= 60) return 20;
  if (pct >= 50) return 10;
  return 5;
}
