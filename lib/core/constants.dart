/// Central place for every tunable rule in the SRS, so the rules can be
/// explained (and changed) in one spot.
class Env {
  /// Defaults point to the Study Flora project, so a plain `flutter run`
  /// (or F5 in VS Code) is online. Override with --dart-define if needed.
  // Study Flora's Supabase project. The publishable key is meant to ship in
  // the app — the tables are protected by Row Level Security.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wfralkzioogiivsntqvc.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_1PaX_APRtsX9yaqm7w-jfA_yNpLcvyF',
  );

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// True only after Supabase.initialize() actually succeeded. If the keys are
  /// wrong the app falls back to demo mode instead of crashing on launch.
  static bool supabaseReady = false;
  static bool get cloud => hasSupabase && supabaseReady;
}

/// Shown in Settings and sent with feedback, so testers can see which build
/// is installed. Keep in step with `version:` in pubspec.yaml.
class AppInfo {
  static const version = '1.1';
  static const build = 2;
  static String get label => 'v$version (build $build)';
}

class GameRules {
  // FR-4.1
  static const potCount = 18;
  static const gardenColumns = 3;

  // FR-4.3 — 6 hours of hydrated growth
  static const growDuration = Duration(hours: 6);

  // FR-4.4 — three visual stages. Seed until 35 %, sprout until 100 %, then bloom.
  static const sproutAt = 0.35;

  // FR-4.5 — each watering gives 2 hours of hydration (max stored: 6 h)
  static const waterGives = Duration(hours: 2);
  static const maxHydration = Duration(hours: 6);

  // Watering can: 3 charges, 1 restored every 10 minutes (Shop mockup)
  static const baseWaterCharges = 3;
  static const chargeRestore = Duration(minutes: 10);
  static const maxCansPerPurchase = 10; // same buy limit as the other tools
  static const maxWaterCharges = baseWaterCharges + 3 * maxCansPerPurchase; // 33

  // FR-4.6 — fertilizer doubles growth speed (once per plant)
  static const fertilizerMultiplier = 2.0;

  // Starting economy: new accounts start at 0 and claim a 150-coin welcome
  // gift from a celebration screen.
  static const welcomeCoins = 150;
  static const startCoins = 0;
  static const startXp = 0;

  // Daily free flower: one random seed per day, ready from 8:00 AM (phone time).
  static const dailyGiftHour = 8;

  // Verified-upload reward (replaces SRS FR-2.5's flat 10 coins — per Paul's
  // update): the user picks ONE garden item per unique file — a random seed,
  // a fertilizer or a shovel. Quantities are kept here so they are easy to tune.
  static const uploadRewardFertilizers = 1;
  static const uploadRewardShovels = 1;

  // Levels use lifetime XP, so spending XP on borders never lowers your level.
  static const xpPerLevel = 200;

  // FR-2.1
  static const maxFileBytes = 25 * 1024 * 1024;

  // FR-3.1 / FR-3.3
  static const maxQuizQuestions = 10;
  static const secondsPerQuestion = 30;

  // FR-3.8
  static const masteredPercent = 60;

  /// FR-3.6 coin table.
  /// First-attempt quiz coins (10 questions): 8–10 correct → 50,
  /// 5–7 correct → 30, 0–4 correct → 5.
  static int quizCoins(int percent) {
    if (percent >= 80) return 50;
    if (percent >= 50) return 30;
    return 5;
  }
}

/// App-wide clock. `offset` powers the "Time skip (demo)" tool in Settings so
/// growth can be shown during a defense without waiting 6 hours.
class GameClock {
  static Duration offset = Duration.zero;
  static DateTime now() => DateTime.now().add(offset);
  static int nowMs() => now().millisecondsSinceEpoch;
}
