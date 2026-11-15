import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Original Study Flora sounds (assets/sounds, generated for this app — no
/// third-party licences). Short UI effects use a small round-robin pool so
/// quick taps can overlap; the garden music loops on its own player.
enum Sfx { tap, swap, plant, water, coin, harvest, success, error, correct, wrong, badge }

class SoundService {
  SoundService._();
  static final instance = SoundService._();

  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool _appVisible = true;

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _music;
  bool _musicPlaying = false;
  bool _musicStarted = false;

  static const _volumes = {
    Sfx.tap: 0.35,
    Sfx.swap: 0.6,
    Sfx.plant: 0.7,
    Sfx.water: 0.7,
    Sfx.coin: 0.65,
    Sfx.harvest: 0.75,
    Sfx.success: 0.7,
    Sfx.error: 0.6,
    Sfx.correct: 0.7,
    Sfx.wrong: 0.6,
    Sfx.badge: 0.8,
  };

  Future<void> init({required bool sfx, required bool music}) async {
    sfxEnabled = sfx;
    musicEnabled = music;
    try {
      // Don't steal focus from the user's own music; mix with it instead.
      await AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        _pool.add(p);
      }
    } catch (e) {
      debugPrint('Sound init failed: $e');
    }
    _syncMusic();
  }

  void play(Sfx s) {
    if (!sfxEnabled || !_appVisible || _pool.isEmpty) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    // Fire-and-forget; a missing sound must never break the UI.
    p.stop().then((_) => p.play(AssetSource('sounds/${s.name}.ogg'), volume: _volumes[s] ?? 0.6)).catchError((Object e) {
      debugPrint('Sound ${s.name} failed: $e');
    });
  }

  void setSfx(bool on) => sfxEnabled = on;

  void setMusic(bool on) {
    musicEnabled = on;
    _syncMusic();
  }

  /// Called from the app lifecycle: music pauses when the app is in the background.
  void setAppVisible(bool visible) {
    _appVisible = visible;
    _syncMusic();
  }

  Future<void> _syncMusic() async {
    final shouldPlay = musicEnabled && _appVisible;
    try {
      if (shouldPlay && !_musicPlaying) {
        _musicPlaying = true;
        if (_musicStarted) {
          await _music!.resume();
        } else {
          _music ??= AudioPlayer();
          await _music!.setReleaseMode(ReleaseMode.loop);
          await _music!.play(AssetSource('sounds/bgm.ogg'), volume: 0.28);
          _musicStarted = true;
        }
      } else if (!shouldPlay && _musicPlaying) {
        await _music?.pause();
        _musicPlaying = false;
      }
    } catch (e) {
      debugPrint('Music failed: $e');
      _musicPlaying = false;
    }
  }
}
