# Crownborn: iOS Game

iOS version of Crownborn: Shattered Lineage

## Prerequisites

- Godot 4.2+
- macOS with Xcode
- Apple Developer Account
- Valid provisioning profile

## Setup

1. Open `godot-project/project.godot` in Godot Editor
2. Download iOS export templates:
   - Go to **Editor > Manage Export Templates**
   - Download iOS templates

3. Configure Xcode:
   - Install Xcode from App Store
   - Install Command Line Tools

## Configure Server

Edit `godot-project/scripts/NetClient.gd`:

```gdscript
const API_BASE = "https://your-server-url.com"
```

## Building

### Export from Godot

1. Project > Export
2. Select iOS preset
3. Configure:
   - Bundle ID: com.crownborn.shatteredlineage
   - App Store Team ID
   - Provisioning Profile UUID
4. Export Project (creates Xcode project)

### Build in Xcode

1. Open exported .xcodeproj
2. Select target device or simulator
3. Configure signing:
   - Team
   - Provisioning Profile
4. Build and run

## App Store Connect

### In-App Purchases

1. Create IAP products in App Store Connect
2. Configure in `PaymentManager.gd`
3. Test with sandbox accounts

### Product IDs

- small_pack
- medium_pack
- large_pack
- mega_pack
- legendary_pack

## Testing

### Simulator
```bash
# Build from Xcode and run in iOS Simulator
```

### TestFlight

1. Archive build in Xcode
2. Upload to App Store Connect
3. Add beta testers
4. Distribute via TestFlight

## Controls

- **Virtual Joystick**: Movement
- **Tap**: Attack
- **Swipe Up**: Jump
- **Two Finger Tap**: Special Attack
- **Long Press**: Power menu
- **3D Touch** (supported devices): Quick power activation

## App Store Submission

### Checklist

- [ ] App icon (all sizes)
- [ ] Screenshots (all device sizes)
- [ ] Privacy policy URL
- [ ] App description
- [ ] Keywords
- [ ] Age rating
- [ ] IAP configured
- [ ] Test on real devices

### Build Process

1. Archive build in Xcode
2. Validate archive
3. Upload to App Store Connect
4. Fill app metadata
5. Submit for review

## Requirements

- iOS 11.0+
- iPhone and iPad support
- Landscape and portrait orientations

## Performance

- Metal renderer (iOS default)
- 60fps target on iPhone X and newer
- Adaptive resolution for older devices
- Battery optimization

## Troubleshooting

### Code Signing Issues
- Verify Team ID
- Check provisioning profile
- Regenerate certificates if needed

### StoreKit Testing
- Use sandbox accounts
- Clear cache if purchases not showing
- Check product IDs match App Store Connect

### Crash on Launch
- Check Xcode console
- Verify all resources included
- Test on actual device, not just simulator
