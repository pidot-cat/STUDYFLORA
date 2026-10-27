# StudyFlora — Flutter (Android)

Flutter/Dart build of the approved StudyFlora mock-ups: auth, onboarding, Home, Garden (18 pots), Study (upload → summary → quiz → results → flash review), Shop, and Settings/Profile. Light and Dark themes are included.

## Setup

1. Create a fresh project (or use your existing one):
   ```
   flutter create --platforms android studyflora
   ```
2. Copy these into the project root, replacing what's there: `lib/`, `assets/`, `pubspec.yaml`, `analysis_options.yaml`.
3. In `android/app/src/main/AndroidManifest.xml`, add this line above `<application>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   Google Fonts and the online check both need it.
4. Run:
   ```
   flutter pub get
   flutter run
   ```

The code requires Dart 3.6+ (Flutter 3.27 or newer). Fonts (Poppins, Plus Jakarta Sans, Playfair Display) download through `google_fonts` the first time the app has internet. After that they're cached.

## Project structure

```
lib/
  main.dart                  app entry, Provider, light/dark ThemeMode
  nav.dart                   pushTab / pushRoot / goTab / goRoot helpers
  theme/                     design tokens (SFColors light+dark) and fonts (T.p / T.j / T.serif)
  models/                    Flower catalog, Plant (growth logic), tools, quiz, modules, avatars, borders, levels
  data/seed_data.dart        starter data shown on a new account (matches the mock-up numbers)
  state/app_state.dart       single ChangeNotifier: auth, garden, shop, study, sync, settings (SharedPreferences)
  services/module_processor  offline PDF/DOCX/TXT text extraction, key points and quiz generation
  widgets/                   shared UI: cards, pills, buttons, header, avatar ring, borders, pots
  screens/
    onboarding/  splash, 3-slide onboarding
    auth/        sign in (+ validation/auth-failure states), create account (+ email-in-use), creating / success / failure,
                 forgot password, reset link sent, set new password, reset success, no internet
    shell/       5-tab shell; each tab has its own Navigator so the bottom bar stays on sub-screens
    home/        home, inventory (seeds / garden tools), all seeds, study "see all", subject progress, study material, summary
    garden/      garden grid + panels, choose flower, confirm planting, water / fertilize / shovel,
                 plant details (both designs), ready to harvest, harvesting, harvest complete
    study/       study review (upload), archived modules, saved module view, full summary, practice quiz,
                 quiz results, review answers, flash review, quiz history, export summary (.txt)
    shop/        seeds (single/bundle), garden tools, borders, purchase sheets, success sheets, insufficient-XP sheet
    settings/    settings, profile & progress, choose avatar, choose border, switch / add account, log out,
                 cloud sync & data, privacy policy, terms of service
```

## Game rules as implemented

- Every flower takes 6 hours to grow, and only grows while it's hydrated. One watering lasts 6 hours.
- The watering can holds 3 charges and gets 1 charge back every 10 minutes. Fertilizer gives 2× speed and can be used once per plant. The shovel removes a plant and is used up.
- Harvesting gives +10 XP and +20 coins, and frees the pot.
- Each new unique file you upload gives +10 coins. Re-uploading the same file just reopens the saved module.
- Quiz coins follow the score bracket on the results screen (100% → 100, 90–99 → 75, 80–89 → 50, 70–79 → 30, 60–69 → 20, 50–59 → 10, below 50 → 5). The pass mark is 60%.
- Levels: Lv1 0–100 XP, Lv2 100–300, Lv3 300–600, Lv4 600–1000, and so on. Avatar borders are bought with XP.

## Things that are local or simulated (no backend)

- **Accounts** are stored on the device (passwords are SHA-256 hashed in SharedPreferences). Sign-in and create-account check for internet first, which is how the "No Internet" and "Account Creation Failed" screens appear.
- **Password reset:** no email gets sent. On "Reset Link Sent", tapping the **Check Your Inbox** card opens the Set New Password screen, standing in for the emailed link.
- **Cloud sync** checks connectivity and records a sync event (Sync history, Last synced). Nothing is uploaded yet. You can plug a real backend into `AppState.sync()` later.
- **Continue with Google** shows a "not available in this build" message.
- **Music, Sound and Notifications** toggles are saved, but no audio or notification system is connected to them yet.

## Notes on the design

- The illustrations that only existed inside the mock-ups (onboarding images, sunflower/daisy pots, tool icons, avatars, cell diagrams, Terms illustration) were cropped from the mock-up PNGs into `assets/`. They're at mock-up resolution, so swap in higher-resolution originals if you have them.
- The 12 flower badge images come from your IMAGES USED folder.
- Icons are Material Icons chosen to match the mock-up glyphs as closely as possible.
- Dark-mode mock-ups existed for Home, Garden, Study, Shop and Settings, and those follow the DM-* designs. Every other screen uses the same dark tokens.
- The splash, onboarding and auth screens were designed in light mode only, so they always render light.
