# background_locator_neo

[![pub package](https://img.shields.io/pub/v/background_locator_neo.svg)](https://pub.dartlang.org/packages/background_locator_neo)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A robust Flutter plugin for receiving location updates even when the app is in the background, killed, or the device has been rebooted. 

This is a modern fork of `background_locator_fixed`, updated for **Flutter 3.x**, **Dart 3.x**, and **Android 14 (API 34)** compatibility.

---

## 🌟 Features

- **Headless Execution**: Receive location updates via a top-level or static Dart callback that runs in its own isolate.
- **Persistence**: Survives app termination (swiped away) and device reboots (Android).
- **Foreground Service**: Fully compliant with Android's Foreground Service requirements for location tracking.
- **Customizable**: Control accuracy, interval, distance filters, and notification appearance.
- **Dual Client Support**: Choose between Google Play Services (Fused) or standard Android Location Manager.

---

## 🚀 Getting Started

### 1. Installation

Add `background_locator_neo` to your `pubspec.yaml`:

```yaml
dependencies:
  background_locator_neo: ^1.0.0
```

### 2. Android Setup

Add the following to your `AndroidManifest.xml`:

```xml
<manifest ...>
    <!-- Permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application ...>
        <!-- Required Service & Receiver -->
        <service
            android:name="upendra.bajpai.background_locator_neo.IsolateHolderService"
            android:permission="android.permission.FOREGROUND_SERVICE"
            android:exported="true"
            android:foregroundServiceType="location" />
            
        <receiver android:name="upendra.bajpai.background_locator_neo.BootBroadcastReceiver"
            android:enabled="true"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 3. Usage

Register your background callback using a top-level function annotated with `@pragma('vm:entry-point')`:

```dart
import 'package:background_locator_neo/background_locator.dart';
import 'package:background_locator_neo/location_dto.dart';
import 'package:background_locator_neo/settings/android_settings.dart';

@pragma('vm:entry-point')
void locationCallback(LocationDto locationDto) {
  print('Location Update: ${locationDto.latitude}, ${locationDto.longitude}');
}

void startLocationService() async {
  await BackgroundLocator.initialize();
  
  await BackgroundLocator.registerLocationUpdate(
    locationCallback,
    androidSettings: AndroidSettings(
      accuracy: LocationAccuracy.NAVIGATION,
      interval: 10,
      distanceFilter: 0,
      androidNotificationSettings: AndroidNotificationSettings(
        notificationChannelName: 'Location tracking',
        notificationTitle: 'Foreground Service Running',
        notificationMsg: 'Tracking location in background',
      )
    )
  );
}
```

---

## 🛠️ Credits & History

This project is a refactored and modernized version of the original `background_locator` plugin. We would like to thank the previous maintainers:
- **Rekab** (Original creator)
- **Yukams** (Maintainer of `background_locator_fixed`)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
