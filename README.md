# pls dont steal if u steal u gay

# AirScope

networking shit

## What is included

- SwiftUI app entry point
- MVVM structure with separate managers for network state, Bonjour discovery, BLE scanning, and latency monitoring
- Dashboard with SSID, local IP, connection type, router latency, Google latency, quality status, and a Swift Charts mini graph
- Bonjour discovery for common local network services
- CoreBluetooth BLE scanner with RSSI bars and sorting
- Pull-to-refresh with light haptic feedback
- Info.plist permission keys for Local Network, Bluetooth, and Location
- Xcode project file targeting iOS 17

## Open it

On macOS with Xcode installed, open:

```text
AirScope.xcodeproj
```
(obviously)

Then choose an iPhone simulator and press Run.

## Build an IPA

On macOS with Xcode installed, open Terminal in this folder and run:

```bash
chmod +x Build/build-ipa.sh
./Build/build-ipa.sh
```

The exported file will be created at:

```text
Build/IPA/AirScope.ipa
```

You need a valid Apple Developer signing setup for an installable device IPA. The export method is currently `development`; change `Build/ExportOptions.plist` to `ad-hoc`, `app-store`, or `enterprise` if your Apple account and provisioning profile support that path.

## Notes

Before shipping, change the bundle identifier from `com.example.AirScope` to one you own in Xcode's target settings.

iOS does not expose MAC addresses or raw ICMP ping to normal App Store apps. AirScope uses public APIs only and shows unavailable placeholders where Apple restricts data.
