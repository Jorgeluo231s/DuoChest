# DuoGacha

Novelty chest for iPhone Duo. Open the hinge past 150° to roll loot. Close it under 10° to reset.

On Windows, open `preview.html` through a local server (`python -m http.server`) and drag the hinge slider. The iPhone app itself still needs Xcode 27.1 on a Mac and an iPhone Duo.

Open `DuoGacha.xcodeproj` in Xcode 27.1 and run it on an iPhone Duo. The hinge is read with `.onHingeChange`. Placeholder art lives in `Assets.xcassets` under `chest_closed`, `chest_opening`, `chest_open`, `gold_coin`, `rubber_duck`, and `old_boot`. The open sound is `DuoGacha/chest_creak.wav`.
