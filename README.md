# Bubble Pop! — a bubble-shooter built with Flutter + Flame

An original bubble-shooter puzzle game (same genre/mechanics as the classic
"Bubble Shooter" style games): aim, shoot, match 3+ bubbles of the same color
to pop them, drop detached clusters for bonus points, and clear the board
before new rows push the bubbles past the red line.

All artwork is **original**: a generated candy-sky backdrop, glossy procedural
bubbles, and Poppy — an animated cartoon mascot who cheers your biggest
combos and droops when you lose.

## Features

### Core gameplay
- Drag anywhere to aim with a dotted trajectory preview (with wall bounces)
- Release to shoot; bubbles snap into the hexagonal grid
- Match 3+ same-color connected bubbles to pop them (particle burst + score popup)
- Detached clusters fall with gravity for bonus points
- Tap the shooter to swap current / next bubble
- A new row pushes down every 5 shots; game over if bubbles cross the red line
- Endless procedurally generated levels (deterministic, so retry = same board)
- More colors and rows as levels progress; score, level, stars, pause menu
- Fully offline, no ads, no tracking

### Engagement pack
- **Combo multiplier** — consecutive popping shots build x2…x8; a miss resets it
- **Daily Challenge** — one board per day, identical for every player (date-seeded), with a saved daily best
- **Level select** — unlock levels by completing them; stars + best score per level
- **Settings** — sound FX, vibration, and colorblind-friendly palette toggles; reset progress
- **Original synthesized sound effects** — pop, shoot, combo, win/lose stingers (no audio assets needed)
- **Game feel** — screen shake on big pops and row drops, pulsing danger line when bubbles creep close, confetti rain on wins, haptic feedback
- **Animated mascot Poppy** — idles with a bob, jumps on big pops and wins, droops on loss

## Run it

```bash
flutter pub get
flutter run
```

Build an installable APK:

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

Build an app bundle for Play Store upload:

```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

## Project layout

```
lib/
  main.dart                  # menu / level select / settings / game screen + HUD overlays
  game/
    bubble_shooter_game.dart # game loop + modes, combo, shake, threat, sounds, saves
    bubble.dart              # glossy procedural Bubble + colorblind-safe palette
    grid.dart                # hex-grid math, flood fill, floating-cluster detection
    level_generator.dart     # deterministic per-level + date-seeded daily boards
    aim_guide.dart           # trajectory dots + direction arrow
    effects.dart             # pop bursts, falling bubbles, score popups, confetti
    visuals.dart             # image-backed background, pulsing danger line, shooter base
    mascot.dart              # animated mascot (idle / celebrate / sad states)
    save_data.dart           # local persistence: scores, stars, unlocks, settings
    sfx.dart                 # sound + haptics helper respecting settings
assets/
  images/
    bg.png                   # candy-sky game backdrop (1080x1920)
    mascot.png               # Poppy, transparent background
    icon-1024.png            # master app icon artwork
  audio/                     # original synthesized SFX (pop, shoot, win, ...)
assets_src/                  # raw generated sources (not bundled)
store/                       # Play Store listing pack
  play-listing-en.txt        # title, short + full description
  icon-512.png               # high-res store icon
  feature-graphic.png        # 1024x500 feature graphic
  privacy-policy.md          # privacy policy draft
  screenshots-HOWTO.md       # how to capture real gameplay screenshots
android/                     # Android runner (applicationId: com.uzairxdev.bubblepop)
test/
  grid_test.dart             # 8 unit tests (grid math, flood fill, generation)
```

## Publishing checklist

1. `flutter build appbundle --release` → upload the `.aab` to Play Console
2. Store listing: copy text from `store/play-listing-en.txt`, upload
   `store/icon-512.png` + `store/feature-graphic.png`
3. Capture 2+ real gameplay screenshots (see `store/screenshots-HOWTO.md`)
4. Fill the Play Console content-rating questionnaire (target: Everyone)
5. Host `store/privacy-policy.md` (e.g. uzairxdev.online/privacy) and link it
6. Roll out to internal testing first, then production

## Ideas to extend

- Sound effects with `flame_audio` (pop, shoot, win/lose stingers)
- Boosters: rainbow bubble, bomb bubble, extra-row remover
- Combo multiplier for consecutive popping shots
- Persist best score / unlocked level with `shared_preferences`
