# Guardian — running & testing

Guardian is an independent observer: host apps (or the mock) report rendered text
via the SDK, and Guardian intercepts those reports and raises the alert. The app
never calls the demo, and the demo never calls the app's engine.

## Prerequisites

- DevEco Studio + HarmonyOS SDK (project builds against `6.1.1(24)`).
- A running emulator/device visible to `hdc`.
- `build-profile.json5` set to `runtimeOS: "HarmonyOS"` (otherwise it targets
  OpenHarmony and will not run on a HarmonyOS emulator).

Set the paths once per PowerShell session:

```powershell
$DEVECO = "D:\Huawei\DevEco Studio"
$PROJ   = "D:\Hackathon\HackYeah\hackyeah2026\HuwaweiChallenge"
$HDC    = "$DEVECO\sdk\default\openharmony\toolchains\hdc.exe"
$TARGET = "127.0.0.1:5555"
```

## 1. Build

```powershell
Set-Location $PROJ; $env:DEVECO_SDK_HOME="$DEVECO\sdk"; & "$DEVECO\tools\node\node.exe" "$DEVECO\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --no-daemon
```

## 2. Install

```powershell
& $HDC -t $TARGET install -r "$PROJ\entry\build\default\outputs\default\entry-default-unsigned.hap"
```

## 3. Start the app once (it then stays in the background)

```powershell
& $HDC -t $TARGET shell aa start -a EntryAbility -b com.example.huwaweichallenge
& $HDC -t $TARGET shell "uitest uiInput keyEvent Home"
```

Registering the SDK subscriber and the global shortcut happens in `EntryAbility`.

## 4. Fire triggers

The mock trigger reports incidents from the knowledge base through the SDK; the
app intercepts them. Each press advances to the next incident (10 total, then it
cycles).

Next incident:

```powershell
& $HDC -t $TARGET shell "uitest uiInput keyEvent 2045 2047 2021"
```

All 10 in a row:

```powershell
1..10 | ForEach-Object { & $HDC -t $TARGET shell "uitest uiInput keyEvent 2045 2047 2021"; Start-Sleep -Milliseconds 1200 }
```

## 5. Live logs

Streams new lines as triggers arrive (Ctrl+C to stop):

```powershell
& $HDC -t $TARGET shell "hilog -T GuardianTrigger,GuardianNotify,GuardianOverlay -v color"
```

Expected sequence per trigger:

```
GuardianTrigger: report incident <id> (<category>/<severity>)
GuardianTrigger: trigger #N via=sdk bundle=com.hackyeah.mockchat ... => <VERDICT>/<category> sev=<SEVERITY> action=ALERT
GuardianOverlay: overlay shown
GuardianNotify: notification #N published: <VERDICT>/<category> via=sdk
```

## Incident order (as in `resources/rawfile/kb/en/incidents.json`)

| # | id | category | severity |
| - | -- | -------- | -------- |
| 0 | family-emergency-money | scam | CRITICAL |
| 1 | misinfo-breaking-event | misinformation | WARNING |
| 2 | bank-authority-impersonation | scam | CRITICAL |
| 3 | delivery-fee-smishing | scam | WARNING |
| 4 | otp-verification-theft | scam | CRITICAL |
| 5 | gift-card-utility-threat | scam | CRITICAL |
| 6 | investment-guaranteed-returns | scam | CRITICAL |
| 7 | romance-scam | scam | WARNING |
| 8 | sextortion-blackmail | harassment | CRITICAL |
| 9 | safe-otp-notice | notice | INFO |

Title comes from `category`, colour from `severity` (`severityColors` in the KB);
the body is the incident's `messages.level0.text`.

## Files this feature touches

New:
- `entry/src/main/ets/kb/IncidentKnowledge.ets`
- `entry/src/main/ets/alert/AlertTheme.ets`
- `entry/src/main/ets/alert/AlertOverlay.ets`
- `entry/src/main/ets/pages/SentinelOverlay.ets`
- `entry/src/main/ets/trigger/MockTriggerController.ets`

Changed:
- `entry/src/main/ets/alert/NotificationService.ets`
- `entry/src/main/ets/entryability/EntryAbility.ets`
- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/sdk/InAppSdkSource.ets`
- `entry/src/main/ets/trigger/IngestSource.ts`
- `entry/src/main/ets/trigger/TriggerEngine.ets`
- `entry/src/main/ets/trigger/TriggerTypes.ts`
- `entry/src/main/module.json5`
- `entry/src/main/resources/base/profile/main_pages.json`
- `guardian_sdk/src/main/ets/GuardianClient.ets`
- `guardian_sdk/src/main/ets/GuardianProtocol.ts`

Not shipped: `oh-package-lock.json5` files (generated) and `build-profile.json5`
(local config).

## Limitations

- The alert overlay uses a `TYPE_FLOAT` window (`ohos.permission.SYSTEM_FLOAT_WINDOW`);
  where the permission is unavailable, only the notification is shown.
- `aa start` on a UIAbility brings the app forward, and a background `appService`
  cannot be started via `aa` (permission denied) — so the console trigger uses the
  global shortcut instead.
- The accessibility source is present but cannot be enabled on a retail build.
