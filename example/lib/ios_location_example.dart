import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 🍏 iOS Background Location Production Guide & Compliance 🍏
/// 
/// To pass Apple's rigorous App Store review for Background Location, you MUST follow these rules:
/// 
/// 1. Info.plist MUST be perfect:
///    - `UIBackgroundModes` array MUST contain `location`.
///    - `NSLocationWhenInUseUsageDescription` & `NSLocationAlwaysAndWhenInUseUsageDescription` MUST be highly specific.
///      *BAD*: "We need your location."
///      *APP STORE APPROVED*: "This app requires background location to track your running distance accurately even when your phone is locked."
/// 
/// 2. Core Feature Requirement:
///    - Apple will reject your app if background location isn't a *core* feature of your app (like a fitness tracker or navigation app). 
///    - You must often provide a video to the reviewers showing exactly why background tracking is necessary.
/// 
/// 3. Battery Optimizations:
///    - Do not use `LocationAccuracy.best` with `distanceFilter: 0` unless absolutely necessary.
///    - Use `pauseLocationUpdatesAutomatically = true` so the OS can sleep the GPS chip when the user stops moving.
///    - Set the correct `ActivityType` (fitness, navigation, etc.). 

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: IosProductionLocationScreen(),
  ));
}

class IosProductionLocationScreen extends StatefulWidget {
  const IosProductionLocationScreen({super.key});

  @override
  State<IosProductionLocationScreen> createState() => _IosProductionLocationScreenState();
}

class _IosProductionLocationScreenState extends State<IosProductionLocationScreen> {
  StreamSubscription<Position>? _positionStream;
  String _status = 'Status: Idle';
  String _location = 'No location yet';
  bool _isTracking = false;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Handles the iOS specific "Always" permission funnel.
  Future<bool> _requestIosPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _status = 'Please enable OS Location Services');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // 1. Initial Prompt usually triggers "When in Use" on iOS.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    // 2. iOS Strict Requirement: We must have user intent to track in background.
    if (permission == LocationPermission.whileInUse) {
      // Prompt user to upgrade to "Always". 
      // NOTE: Apple requires that users can still use your app even if they reject "Always".
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<void> _startIosTracking() async {
    bool hasPermission = await _requestIosPermissions();
    if (!hasPermission) return;

    // 🍏 iOS Specific Production Settings 🍏
    // These settings are heavily scrutinized by Apple to prevent battery drain.
    final locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high, // Avoid 'bestForNavigation' unless it's a driving app
      
      // activityType helps iOS algorithms decide when to pause updates to save battery.
      // Use automotiveNavigation, fitness, airborne, or other. 
      activityType: ActivityType.fitness, 
      
      // Let the OS pause location hardware if the user sits totally still.
      pauseLocationUpdatesAutomatically: true,
      
      // Only fire Dart code if they move at least 5 meters. Do not set this to 0 in production!
      distanceFilter: 5, 
      
      // CRITICAL: This is what keeps the location tracking alive when minimized.
      allowBackgroundLocationUpdates: true,
      
      // Set to true if you are okay with a blue pill at the top of the screen when they grant "When In Use".
      showBackgroundLocationIndicator: true, 
    );

    setState(() {
      _isTracking = true;
      _status = 'Tracking (iOS Compliant Mode)';
    });

    _positionStream ??= Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _location = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    if (mounted) setState(() {
      _isTracking = false;
      _status = 'Status: Stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iOS compliant Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(color: CupertinoColors.systemGrey)),
            const SizedBox(height: 20),
            Text(_location, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isTracking ? _stopTracking : _startIosTracking,
              child: Text(_isTracking ? 'Stop Tracking' : 'Start iOS Background Tracking'),
            )
          ],
        ),
      ),
    );
  }
}
