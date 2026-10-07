# Screenshots — how to capture for the Play listing

Google Play requires **at least 2 screenshots** (phone). They must be real
captures of your game — do not use mockups or AI images.

## Capture steps
1. Connect your Android phone via USB (enable USB debugging) or run an
   emulator.
2. From the project root:
   ```
   flutter run --release
   ```
3. Play to a good moment (mid-level with lots of bubbles, a big pop, the
   mascot visible), then in a second terminal:
   ```
   flutter screenshot
   ```
   This saves a PNG using the device's real resolution.
4. Capture 4–6 shots: gameplay, a big pop moment, level-complete stars,
   game-over screen, pause menu.

## Tips
- Use a phone in portrait; screenshots should be 9:16 (e.g. 1080×1920).
- Play Console also accepts 16:9 landscape, but portrait matches the game.
- The feature graphic (`store/feature-graphic.png`, 1024×500) and the
  high-res icon (`store/icon-512.png`, 512×512) in this folder are ready
  to upload as-is.

## Upload checklist (Play Console → Store presence → Main store listing)
- [ ] App icon: `store/icon-512.png`
- [ ] Feature graphic: `store/feature-graphic.png`
- [ ] Phone screenshots (2–8)
- [ ] Title, short + full description: `store/play-listing-en.txt`
- [ ] Privacy policy URL: host `store/privacy-policy.md` (e.g. as a page on
      uzairxdev.online/privacy) and paste the link
