# Study Flora

A gamified study and quiz reviewer for students, built with Flutter and Dart for Android only.
Upload your notes and the app pulls out key points and builds a practice quiz. Verified modules,
quizzes and harvests earn rewards that grow your Zen Garden.

## Run it

```bash
flutter pub get
flutter run                      # demo mode: accounts are stored on the phone
# or, with cloud login + sync:
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
flutter test                     # garden-rule and analyzer unit tests
```

### Supabase setup (online features)
1. Create a Supabase project. Under **Authentication**, turn on the Email provider.
2. Open **SQL Editor** and run `supabase/schema.sql`. It creates the `user_data` and `quiz_attempts` tables with Row Level Security.
3. Run the app with the two `--dart-define` values from **Project Settings → API**.

When the keys are missing, the sign-in screen shows a **Demo mode** banner. Accounts, login and the
password reset then work on the phone only, so the app can still be graded offline.

## Project structure (SRS §5)

```
lib/
  core/        constants.dart (all game rules), theme.dart (light + dark tokens), format.dart
  models/      flower, pot (growth math), study (module, quiz), cosmetics (avatars, borders, badges, tools)
  services/    storage, auth (Supabase), sync, text_extractor (PDF/DOCX/TXT), text_analyzer,
               module_validator, quiz_generator
  providers/   game, study, settings, auth, sync, feedback_bus (Provider / ChangeNotifier)
  widgets/     common UI kit, plant + profile widgets, bottom sheets
  screens/     splash, onboarding, auth/, home/, garden/, study/, shop/, settings/
assets/        plants (seed / sprout / bloom / wilted × 12), avatars, borders, tools, images, fonts
```

## Key features
| Area | What it does |
|---|---|
| **Plant stages** | Every flower goes through 3 stages. Stage 1 is the **seed**, stage 2 is the **sprout** (budding petals, from 35 % growth) and stage 3 is the **full bloom**, which can be claimed for XP or left on display. A dry sprout shows the wilted art. |
| **Growth rules** | Each flower needs 6 h of *hydrated* growth. A newly planted seed starts dry, and each watering adds 2 h. Growth pauses at 0 hydration. Fertilizer gives 2× speed (it halves the remaining time and the % does not jump), once per plant. The Shovel removes a plant after you confirm. |
| **Drag-and-drop garden** | The whole garden fits on one screen (no scrolling). Long-press any pot, or turn on **Arrange**, then drop it on another pot. The pot moves with its plant, the other pot glides into the empty spot, and the drop ends with a bounce. |
| **Home hero** | The most important plant is shown big in a terracotta pot, with a timer, a hydration bar, and a *Ready to Harvest*, *Needs water* or *Growing* badge. |
| **Upload reward** | The file is checked for type, size (25 MB max), readable text, full sentences, at least 3 key points, lesson structure and repetitive filler. A **verified** module lets you choose **a random seed, 50 coins or 50 XP**, once per unique file (SHA-256 duplicate check). |
| **Quiz** | Up to 10 questions of 3 types, 30 s each, with flagging, instant feedback and a running score. Coins follow the FR-3.6 table, and a module counts as mastered at 60 % or higher. |
| **Shop** | Seeds can be bought singly or as a bundle of 5. Garden tools are bought with coins. Avatar borders are bought with **XP**, and **each border comes with a matching badge**. |
| **Badges** | There are 5 border badges and 10 achievements (First Sprout, Quiz Ace, Botanist…). Achievements have rewards you can claim, and one badge can be showcased on your profile. |
| **Offline-first sync** | Every change is saved on the phone and queued. Sync runs when you are online. Quiz attempts are merged by id, modules by file hash, and the newer game state wins. Sync status and Retry are in Settings. |
| **Testing (demo)** | Settings → *Time skip* moves the garden clock forward so all 3 stages can be shown in a defense. |

## Changes to the SRS that should be written in
* **FR-2.5**: change "10 coins once per unique file" to "a verified upload lets the user choose a random seed, 50 coins or 50 XP, once per unique file".
* **FR-4.4**: name the stages *seed → sprout (budding petals) → full bloom*.
* **FR-5.2**: add "each avatar border comes with a badge of the same theme", plus an achievement-badge system.
* The upload validation checklist (the "proof that the file is a real module" rules) is in `services/module_validator.dart`.
