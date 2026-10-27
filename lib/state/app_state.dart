import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/models.dart';

enum AuthResult { ok, invalidEmail, wrongCredentials, emailInUse, passwordMismatch, weakPassword, offline, failed }

/// Single source of truth for StudyFlora. Persists everything locally with
/// SharedPreferences (one JSON blob per account).
class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  Timer? _ticker;
  bool loaded = false;

  // ---- device settings ----
  bool darkMode = false;
  bool music = true;
  bool sound = true;
  bool notifications = true;
  bool onboardingDone = false;

  // ---- accounts ----
  List<SavedAccount> accounts = [];
  List<String> signedInEmails = []; // accounts available in Switch Account
  String? currentEmail;

  // ---- per-user data ----
  int coins = 0;
  int xp = 0;
  Map<String, int> seeds = {};
  Map<ToolType, int> tools = {};
  DateTime waterRegenAt = DateTime.now();
  List<Plant> plants = [];
  List<StudyModule> modules = [];
  List<QuizAttempt> history = [];
  Set<String> uploadedHashes = {};
  String avatarId = 'flora_bear';
  String borderId = 'starter';
  Set<String> ownedBorders = {'starter'};
  List<SyncEvent> syncEvents = [];
  DateTime? lastSynced;

  SavedAccount? get account =>
      accounts.where((a) => a.email == currentEmail).cast<SavedAccount?>().firstWhere((_) => true, orElse: () => null);
  String get displayName => account?.name ?? 'StudyFlora';
  String get email => account?.email ?? 'student@studyflora.app';
  int get level => Levels.level(xp);
  int get nextLevelXp => Levels.nextThreshold(xp);
  double get levelProgress => math.min(1.0, xp / nextLevelXp);
  AvatarOption get avatar => AvatarOption.byId(avatarId);
  BorderOption get border => BorderOption.byId(borderId);
  int get totalSeeds => seeds.values.fold(0, (a, b) => a + b);
  int get totalTools => tools.values.fold(0, (a, b) => a + b);
  int seedCount(String id) => seeds[id] ?? 0;
  int toolCount(ToolType t) => tools[t] ?? 0;
  Plant? plantAt(int pot) =>
      plants.where((p) => p.pot == pot).cast<Plant?>().firstWhere((_) => true, orElse: () => null);
  List<String> get ownedSeedIds => Flowers.all.where((f) => seedCount(f.id) > 0).map((f) => f.id).toList();

  // ------------------------------------------------------------------ init
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    darkMode = _prefs.getBool('darkMode') ?? false;
    music = _prefs.getBool('music') ?? true;
    sound = _prefs.getBool('sound') ?? true;
    notifications = _prefs.getBool('notifications') ?? true;
    onboardingDone = _prefs.getBool('onboardingDone') ?? false;
    accounts = (jsonDecode(_prefs.getString('accounts') ?? '[]') as List)
        .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    signedInEmails = _prefs.getStringList('signedIn') ?? [];
    currentEmail = _prefs.getString('currentEmail');
    if (currentEmail != null) _loadUser(currentEmail!);
    loaded = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (currentEmail == null) return;
    final now = DateTime.now();
    for (final p in plants) {
      p.tick(now);
    }
    _regenWater(now);
    if (plants.isNotEmpty) notifyListeners();
  }

  void _regenWater(DateTime now) {
    final cans = toolCount(ToolType.wateringCan);
    if (cans >= GardenRules.waterCapacity) {
      waterRegenAt = now;
      return;
    }
    final steps = now.difference(waterRegenAt).inMilliseconds ~/ GardenRules.waterRegen.inMilliseconds;
    if (steps > 0) {
      tools[ToolType.wateringCan] = math.min(GardenRules.waterCapacity, cans + steps);
      waterRegenAt = waterRegenAt.add(GardenRules.waterRegen * steps);
      _save();
    }
  }

  // ---------------------------------------------------------------- settings
  void setDark(bool v) {
    darkMode = v;
    _prefs.setBool('darkMode', v);
    notifyListeners();
  }

  void setMusic(bool v) {
    music = v;
    _prefs.setBool('music', v);
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    _prefs.setBool('sound', v);
    notifyListeners();
  }

  void setNotifications(bool v) {
    notifications = v;
    _prefs.setBool('notifications', v);
    notifyListeners();
  }

  void completeOnboarding() {
    onboardingDone = true;
    _prefs.setBool('onboardingDone', true);
    notifyListeners();
  }

  // -------------------------------------------------------------------- auth
  static String _hash(String s) => sha256.convert(utf8.encode(s)).toString();
  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static bool validEmail(String e) => _emailRe.hasMatch(e.trim());
  static bool strongPassword(String p) => p.length >= 8 && RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(p);

  /// 0..1 strength used by the "Seedling Strength" meter.
  static double passwordStrength(String p) {
    var s = 0.0;
    if (p.length >= 8) s += .35;
    if (p.length >= 12) s += .15;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += .15;
    if (RegExp(r'[0-9]').hasMatch(p)) s += .2;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s += .15;
    return math.min(1.0, s);
  }

  Future<bool> isOnline() async {
    try {
      final r = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> signIn(String email, String password) async {
    email = email.trim().toLowerCase();
    if (!validEmail(email)) return AuthResult.invalidEmail;
    await Future.delayed(const Duration(milliseconds: 900));
    final acc = accounts.where((a) => a.email == email).toList();
    if (acc.isEmpty || acc.first.passwordHash != _hash(password)) return AuthResult.wrongCredentials;
    _activate(email);
    return AuthResult.ok;
  }

  bool emailExists(String email) => accounts.any((a) => a.email == email.trim().toLowerCase());

  Future<AuthResult> signUp(String name, String email, String password, String confirm) async {
    email = email.trim().toLowerCase();
    if (!validEmail(email)) return AuthResult.invalidEmail;
    if (emailExists(email)) return AuthResult.emailInUse;
    if (password != confirm) return AuthResult.passwordMismatch;
    if (password.length < 8) return AuthResult.weakPassword;
    await Future.delayed(const Duration(milliseconds: 1600));
    try {
      accounts.add(SavedAccount(email, name.trim().isEmpty ? 'StudyFlora' : name.trim(), _hash(password)));
      await _prefs.setString('accounts', jsonEncode(accounts.map((a) => a.toJson()).toList()));
      _seedNewUser();
      currentEmail = email;
      await _save();
      _activate(email);
      return AuthResult.ok;
    } catch (_) {
      return AuthResult.failed;
    }
  }

  /// Local-only password reset (no email server). Updates the stored hash.
  Future<bool> resetPassword(String email, String newPassword) async {
    email = email.trim().toLowerCase();
    final i = accounts.indexWhere((a) => a.email == email);
    if (i < 0) return false;
    accounts[i] = SavedAccount(email, accounts[i].name, _hash(newPassword));
    await _prefs.setString('accounts', jsonEncode(accounts.map((a) => a.toJson()).toList()));
    return true;
  }

  void _activate(String email) {
    currentEmail = email;
    if (!signedInEmails.contains(email)) signedInEmails.add(email);
    _prefs.setString('currentEmail', email);
    _prefs.setStringList('signedIn', signedInEmails);
    _loadUser(email);
    notifyListeners();
  }

  Future<void> switchAccount(String email) async {
    await _save();
    _activate(email);
  }

  Future<void> logout() async {
    await _save();
    signedInEmails.remove(currentEmail);
    currentEmail = null;
    await _prefs.remove('currentEmail');
    await _prefs.setStringList('signedIn', signedInEmails);
    notifyListeners();
  }

  Future<void> logoutAll() async {
    await _save();
    signedInEmails.clear();
    currentEmail = null;
    await _prefs.remove('currentEmail');
    await _prefs.setStringList('signedIn', []);
    notifyListeners();
  }

  void rename(String name) {
    final i = accounts.indexWhere((a) => a.email == currentEmail);
    if (i < 0 || name.trim().isEmpty) return;
    accounts[i] = SavedAccount(accounts[i].email, name.trim(), accounts[i].passwordHash);
    _prefs.setString('accounts', jsonEncode(accounts.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  /// Summary for the Switch Account list (reads other users' saved blobs).
  Map<String, dynamic> accountSummary(String email) {
    final raw = _prefs.getString('user_$email');
    if (raw == null) return {'xp': 0, 'pots': GardenRules.potCount, 'avatar': 'flora_bear'};
    final j = jsonDecode(raw);
    return {'xp': j['xp'] ?? 0, 'pots': GardenRules.potCount, 'avatar': j['avatar'] ?? 'flora_bear'};
  }

  // --------------------------------------------------------------- user data
  void _seedNewUser() {
    final now = DateTime.now();
    coins = 340;
    xp = 320;
    seeds = {'sunflower': 2, 'tulip': 3, 'lavender': 1, 'rose': 2, 'daisy': 1, 'cosmos': 1};
    tools = {ToolType.wateringCan: 3, ToolType.fertilizer: 2, ToolType.shovel: 1};
    waterRegenAt = now;
    final total = GardenRules.growDuration.inMilliseconds;
    plants = [
      Plant(
          flowerId: 'sunflower', pot: 1, growthMs: (total * .42).round(), hydration: 80, lastTick: now, plantedAt: now),
      Plant(flowerId: 'lavender', pot: 2, growthMs: (total * .3).round(), hydration: 0, lastTick: now, plantedAt: now),
      Plant(flowerId: 'rose', pot: 3, growthMs: (total * .74).round(), hydration: 70, lastTick: now, plantedAt: now),
    ];
    modules = SeedData.modules(now);
    history = SeedData.history(now);
    uploadedHashes = {};
    avatarId = 'flora_bear';
    borderId = 'starter';
    ownedBorders = {'starter'};
    syncEvents = [];
    lastSynced = null;
  }

  void _loadUser(String email) {
    final raw = _prefs.getString('user_$email');
    if (raw == null) {
      _seedNewUser();
      _save();
      return;
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    coins = j['coins'];
    xp = j['xp'];
    seeds = Map<String, int>.from(j['seeds']);
    tools = {for (final t in ToolType.values) t: (j['tools'][t.name] ?? 0) as int};
    waterRegenAt = DateTime.fromMillisecondsSinceEpoch(j['waterRegenAt']);
    plants = (j['plants'] as List).map((e) => Plant.fromJson(Map<String, dynamic>.from(e))).toList();
    modules = (j['modules'] as List).map((e) => StudyModule.fromJson(Map<String, dynamic>.from(e))).toList();
    history = (j['history'] as List).map((e) => QuizAttempt.fromJson(Map<String, dynamic>.from(e))).toList();
    uploadedHashes = Set<String>.from(j['hashes'] ?? []);
    avatarId = j['avatar'] ?? 'flora_bear';
    borderId = j['border'] ?? 'starter';
    ownedBorders = Set<String>.from(j['ownedBorders'] ?? ['starter']);
    syncEvents = ((j['sync'] ?? []) as List).map((e) => SyncEvent.fromJson(Map<String, dynamic>.from(e))).toList();
    lastSynced = j['lastSynced'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['lastSynced']);
    final now = DateTime.now();
    for (final p in plants) {
      p.tick(now); // catch up offline growth
    }
    _regenWater(now);
  }

  Future<void> _save() async {
    if (currentEmail == null) return;
    final j = {
      'coins': coins,
      'xp': xp,
      'seeds': seeds,
      'tools': {for (final e in tools.entries) e.key.name: e.value},
      'waterRegenAt': waterRegenAt.millisecondsSinceEpoch,
      'plants': plants.map((p) => p.toJson()).toList(),
      'modules': modules.map((m) => m.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
      'hashes': uploadedHashes.toList(),
      'avatar': avatarId,
      'border': borderId,
      'ownedBorders': ownedBorders.toList(),
      'sync': syncEvents.map((e) => e.toJson()).toList(),
      'lastSynced': lastSynced?.millisecondsSinceEpoch,
    };
    await _prefs.setString('user_$currentEmail', jsonEncode(j));
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  // ------------------------------------------------------------------- shop
  static const seedPrice = 50;
  static const bundlePrice = 200;

  bool buySeeds(String flowerId, {required bool bundle, int qty = 1}) {
    final cost = (bundle ? bundlePrice : seedPrice) * qty;
    if (coins < cost) return false;
    coins -= cost;
    seeds[flowerId] = seedCount(flowerId) + (bundle ? 5 : 1) * qty;
    _commit();
    return true;
  }

  bool buyTool(ToolType t, int qty) {
    final cost = ToolInfo.of(t).price * qty;
    if (coins < cost) return false;
    coins -= cost;
    tools[t] = toolCount(t) + qty;
    _commit();
    return true;
  }

  bool buyBorder(String id) {
    final b = BorderOption.byId(id);
    if (ownedBorders.contains(id)) return true;
    if (xp < b.xpCost) return false;
    xp -= b.xpCost;
    ownedBorders.add(id);
    _commit();
    return true;
  }

  void equipBorder(String id) {
    if (!ownedBorders.contains(id)) return;
    borderId = id;
    _commit();
  }

  void setAvatar(String id) {
    avatarId = id;
    _commit();
  }

  // ----------------------------------------------------------------- garden
  bool plant(int pot, String flowerId) {
    if (plantAt(pot) != null || seedCount(flowerId) <= 0) return false;
    final now = DateTime.now();
    seeds[flowerId] = seedCount(flowerId) - 1;
    if (seeds[flowerId] == 0) seeds.remove(flowerId);
    plants.add(Plant(flowerId: flowerId, pot: pot, lastTick: now, plantedAt: now));
    _commit();
    return true;
  }

  bool water(int pot) {
    final p = plantAt(pot);
    if (p == null || toolCount(ToolType.wateringCan) <= 0) return false;
    if (toolCount(ToolType.wateringCan) >= GardenRules.waterCapacity) waterRegenAt = DateTime.now();
    tools[ToolType.wateringCan] = toolCount(ToolType.wateringCan) - 1;
    p.tick(DateTime.now());
    p.hydration = 100;
    _commit();
    return true;
  }

  bool fertilize(int pot) {
    final p = plantAt(pot);
    if (p == null || p.fertilized || toolCount(ToolType.fertilizer) <= 0) return false;
    tools[ToolType.fertilizer] = toolCount(ToolType.fertilizer) - 1;
    p.tick(DateTime.now());
    p.fertilized = true;
    _commit();
    return true;
  }

  bool shovel(int pot) {
    final p = plantAt(pot);
    if (p == null || toolCount(ToolType.shovel) <= 0) return false;
    tools[ToolType.shovel] = toolCount(ToolType.shovel) - 1;
    plants.remove(p);
    _commit();
    return true;
  }

  /// Returns the XP earned (0 if not ready).
  int harvest(int pot) {
    final p = plantAt(pot);
    if (p == null || !p.ready) return 0;
    xp += p.flower.rewardXp;
    coins += p.flower.rewardCoins;
    plants.remove(p);
    _commit();
    return p.flower.rewardXp;
  }

  // ------------------------------------------------------------------ study
  /// Adds a processed module. Returns true when coins were awarded (unique file).
  bool addModule(StudyModule m, String fileHash) {
    final unique = !uploadedHashes.contains(fileHash);
    if (unique) {
      uploadedHashes.add(fileHash);
      coins += 10;
      modules.insert(0, m);
    } else {
      final i = modules.indexWhere((x) => x.fileName == m.fileName);
      if (i >= 0) {
        final existing = modules.removeAt(i);
        modules.insert(0, existing);
      } else {
        modules.insert(0, m);
      }
    }
    _commit();
    return unique;
  }

  StudyModule? moduleById(String id) =>
      modules.where((m) => m.id == id).cast<StudyModule?>().firstWhere((_) => true, orElse: () => null);

  int attemptsFor(String moduleId) => history.where((h) => h.moduleId == moduleId).length;

  QuizAttempt recordAttempt(StudyModule m, List<int?> answers, List<bool> flagged) {
    final tmp = QuizAttempt(
        moduleId: m.id,
        title: m.title,
        fileName: m.fileName,
        date: DateTime.now(),
        attemptNo: attemptsFor(m.id) + 1,
        answers: answers,
        flagged: flagged,
        questions: m.questions,
        coins: 0);
    final earned = coinsForPercent(tmp.percent);
    final attempt = QuizAttempt(
        moduleId: tmp.moduleId,
        title: tmp.title,
        fileName: tmp.fileName,
        date: tmp.date,
        attemptNo: tmp.attemptNo,
        answers: answers,
        flagged: flagged,
        questions: m.questions,
        coins: earned);
    coins += earned;
    if (attempt.percent > m.bestScore) m.bestScore = attempt.percent;
    history.insert(0, attempt);
    _commit();
    return attempt;
  }

  // ------------------------------------------------------------------- sync
  /// Local-first "cloud" sync: verifies connectivity and stamps a sync event.
  Future<bool> sync({bool manual = true}) async {
    final ok = await isOnline();
    await Future.delayed(const Duration(milliseconds: 800));
    final ev = SyncEvent(DateTime.now(), ok, manual);
    syncEvents.insert(0, ev);
    if (syncEvents.length > 10) syncEvents = syncEvents.take(10).toList();
    if (ok) lastSynced = ev.at;
    _commit();
    return ok;
  }
}
