class StorageKeys {
  const StorageKeys._();

  static const darkMode = 'dark_mode';
  static const name = 'user_name';
  static const email = 'user_email';
  static const coins = 'user_coins';
  static const xp = 'user_xp';
  static const lifetimeXp = 'user_lifetime_xp';
  static const streak = 'user_streak';
  static const ownedBorders = 'owned_borders';
  static const equippedBorder = 'equipped_border';
  static const music = 'pref_music';
  static const sound = 'pref_sound';
  static const notifications = 'pref_notifications';
  static const studyModules = 'study_modules';
  static const studyCurrent = 'study_current';
  static const quizResults = 'quiz_results';
  static const gardenPots = 'garden_pots';
  static const gardenCharges = 'garden_charges';
  static const gardenChargeAt = 'garden_charge_at';

  /// Inventory counts are stored per item: `inv_<itemId>`.
  static String inventory(String itemId) => 'inv_$itemId';
}
