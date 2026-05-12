# iOS26Anim

Approximates iOS 26 app open/close animations on iOS 16.7.x (RootHide Dopamine).

## Target
- iPhone 8
- iOS 16.7.15
- Dopamine RootHide (rootless)
- ellekit (substrate provider, comes with Dopamine)

## Building
You need Theos installed on macOS or Linux with the rootless SDK.

```bash
# Set up Theos if you haven't already
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos

# Grab the rootless iOS 16 SDK
curl -L https://github.com/theos/sdks/archive/master.zip -o sdks.zip
unzip sdks.zip 'sdks-master/iPhoneOS16.5.sdk/*'
mv sdks-master/iPhoneOS16.5.sdk $THEOS/sdks/
rm -rf sdks.zip sdks-master

# Build
cd iOS26Anim
make package FINALPACKAGE=1
```

The output `.deb` will be in `./packages/`.

## Installing
1. Transfer the `.deb` to your iPhone (AirDrop, Filza, scp, etc.)
2. Open it with **Sileo** or **TrollStore**'s package installer
3. SpringBoard will respring
4. Open any app — you should feel the snappier, bouncier transition with a brief glass haze

## Tuning
Edit the constants at the top of `Tweak.x`:

| Constant | What it does |
|---|---|
| `kOpenResponse` | Lower = snappier open. Try 0.35–0.50 |
| `kOpenDamping` | Higher = less bounce. Try 0.80–0.95 |
| `kCloseResponse` / `kCloseDamping` | Same, for app → home |
| `kOpenDuration` / `kCloseDuration` | Absolute cap on duration |
| `kGlassBlurAlpha` | 0.0 disables the glass overlay |

Rebuild and reinstall after editing.

## Known limits
- The "liquid glass" refraction in real iOS 26 uses private Metal shaders that don't exist on iOS 16. We fake the haze with `UIVisualEffectView`.
- Some animation paths (e.g. CarPlay, multi-window iPad transitions) aren't covered — this is SpringBoard-iPhone only.
- If the spring filter heuristic misfires on your build, you may notice folder/dock animations also feeling different. Tighten the `if (v > 0.35 && v < 0.75)` range in `SBFluidBehaviorSettings`.

## Uninstall
Remove via Sileo. SpringBoard will respring back to stock.
