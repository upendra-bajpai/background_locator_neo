# Background Locator Neo: Modernization Guide

This guide covers the technical details of the **v1.1.0** update, focusing on compatibility with **Android 14 (API 34/35/36)** and **iOS 13+** modernization.

---

## 🤖 Android 14+ Stabilization

Android 14 introduced strict requirements for background services, especially those using `location`.

### 1. Build Configuration
The plugin is now optimized for:
- **Android SDK**: 35/36 (target/compile)
- **Kotlin**: 2.1.0
- **AGP**: 8.7.0
- **Java**: 17 (JVM 17)

### 2. Foreground Service Type
You MUST declare the `location` service type in your `AndroidManifest.xml` (the plugin handles this, but your app must satisfy the permission requirements):
```xml
<service
    android:name="upendra.bajpai.background_locator_neo.IsolateHolderService"
    android:foregroundServiceType="location"
    android:exported="true" />
```

### 3. Permissions
Ensure you request `ACCESS_BACKGROUND_LOCATION` in addition to fine/coarse location. For Android 14, high-precision tracking requires clear user intent.

---

## 🍎 iOS Modernization (iOS 13+)

We have introduced new properties to `IOSSettings` to give you better control over power and precision.

### 1. New Settings Properties
- `pausesLocationUpdatesAutomatically`: (bool) Allows iOS to pause updates to save power when the device is stationary.
- `activityType`: (LocationActivityType) Optimizes the system for specific movements (e.g., `automotiveNavigation`, `fitness`).

### 2. Critical Setup: AppDelegate.swift
For background isolates to work correctly on iOS, you **must** register the plugin registrant callback in your `AppDelegate`:

```swift
import background_locator_neo

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // ⚡ REQUIRED for background tracking
    BackgroundLocatorPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 🔗 Identity Synchronization
If you are migrating from an older fork, ensure your `Keys.kt` (Android) and `Globals.h/m` (iOS) are using the synchronized channel identifier:
`upendra.bajpai.background_locator_neo/locator_plugin`

Legacy `app.yukams` identifiers will cause `MissingPluginException`.
