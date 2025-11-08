# Crownborn: Android Game

Android version of Crownborn: Shattered Lineage

## Prerequisites

- Godot 4.2+
- Android SDK
- Java JDK 11+

## Setup

1. Open `godot-project/project.godot` in Godot Editor
2. Configure Android export template:
   - Go to **Editor > Manage Export Templates**
   - Download Android templates

3. Set up Android SDK:
   - Go to **Editor > Editor Settings > Export > Android**
   - Set Android SDK path
   - Set debug keystore (for testing)

## Configure Server

Edit `godot-project/scripts/NetClient.gd`:

```gdscript
const API_BASE = "https://your-server-url.com"
```

## Building

### Debug Build (APK)

1. Project > Export
2. Select Android preset
3. Export as APK
4. Install on device: `adb install crownborn.apk`

### Release Build (AAB for Play Store)

1. Create release keystore
2. Project > Export > Android
3. Configure signing:
   - Keystore path
   - Keystore password
   - Key alias
4. Export as AAB
5. Upload to Google Play Console

## Google Play Integration

### In-App Purchases

1. Create products in Play Console
2. Update `PaymentManager.gd` with product IDs
3. Test with test accounts

### Product IDs

- small_pack
- medium_pack
- large_pack
- mega_pack
- legendary_pack

## Testing

### On Device
```bash
adb install builds/android/crownborn.apk
adb logcat | grep Godot
```

### Remote Debugging

Enable remote debug in export settings, then connect via Godot debugger.

## Project Structure

```
godot-project/
├── scripts/          # GDScript files
│   ├── GameState.gd
│   ├── Player.gd
│   ├── Enemy.gd
│   ├── Boss.gd
│   ├── NetClient.gd
│   └── ...
├── scenes/           # Game scenes (created in editor)
├── data/             # Mission JSON files
├── resources/        # Game resources
└── project.godot     # Godot configuration
```

## Controls

- **Virtual Joystick**: Movement
- **Tap**: Attack
- **Swipe Up**: Jump
- **Two Finger Tap**: Special Attack
- **Hold & Swipe**: Power activation
- **Shake Device**: Summon Shaman (rub ring alternative)

## Performance Optimization

- Dynamic resolution scaling
- LOD meshes
- Occlusion culling
- Texture compression (ASTC/ETC2)
- Target: 60fps on mid-range devices

## Troubleshooting

### Build Fails
- Check Android SDK path
- Verify Godot export templates installed
- Check keystore configuration

### Game Crashes
- Check logcat: `adb logcat | grep Godot`
- Verify server connectivity
- Check memory usage

### IAP Not Working
- Verify product IDs match Play Console
- Test with test account
- Check server receipt validation
