import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

// Background Locator Dependencies
import 'package:background_locator_neo/background_locator.dart';
import 'package:background_locator_neo/settings/android_settings.dart';
import 'package:background_locator_neo/settings/ios_settings.dart';
import 'package:background_locator_neo/settings/locator_settings.dart';
import 'package:background_locator_neo/location_dto.dart';

const String _isolateName = "LocatorIsolate";
final ReceivePort port = ReceivePort();

void main() {
  runApp(const MyApp());
}

// ----------------------------------------------------------------------
// ⚡ HEADLESS ISOLATE CALLBACKS ⚡
// These MUST remain top-level static functions outside of any class.
// They execute in a completely isolated Dart memory space when the UI is killed!
// ----------------------------------------------------------------------

@pragma('vm:entry-point')
void locationCallback(LocationDto locationDto) async {
  // If the app UI is actually alive, send it via the Port!
  final SendPort? send = IsolateNameServer.lookupPortByName(_isolateName);
  send?.send(locationDto.toJson());
  
  // This print will appear in logcat even if the app UI is totally dead.
  print('🗡️ [ISOLATE LOG] LocationTrigger: ${locationDto.latitude}, ${locationDto.longitude}');
}

@pragma('vm:entry-point')
void initCallback(Map<dynamic, dynamic> params) {
  print('🗡️ [ISOLATE LOG] Plugin initialized in background');
}

@pragma('vm:entry-point')
void disposeCallback() {
  print('🗡️ [ISOLATE LOG] Plugin cleanup');
}

@pragma('vm:entry-point')
void notificationCallback() {
  print('🗡️ [ISOLATE LOG] User clicked the notification');
}

// ----------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Headless Location Tracker',
      debugShowCheckedModeBanner: false,
      home: HelloWorldScreen(),
    );
  }
}

class HelloWorldScreen extends StatefulWidget {
  const HelloWorldScreen({super.key});

  @override
  State<HelloWorldScreen> createState() => _HelloWorldScreenState();
}

class _HelloWorldScreenState extends State<HelloWorldScreen> {
  String _locationStatus = 'Status: Stopped / Init';
  String _currentLocation = 'Lat: -, Lon: -';
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    
    // Bind the isolate receive port so the UI can update when it's alive
    IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);
    port.listen((dynamic data) {
      if (data is Map) {
        final double lat = data['latitude'] ?? 0.0;
        final double lon = data['longitude'] ?? 0.0;
        if (mounted) {
          setState(() {
            _currentLocation = 'Lat: ${lat.toStringAsFixed(5)}, Lon: ${lon.toStringAsFixed(5)}';
          });
        }
      }
    });

    _initBackgroundLocator();
  }

  Future<void> _initBackgroundLocator() async {
    // Initializes native platform channels for the background service
    await BackgroundLocator.initialize();
    
    // Check if it's already running from a previous launch/reboot
    bool isRunning = await BackgroundLocator.isServiceRunning();
    if (mounted) {
      setState(() {
        _isTracking = isRunning;
        _locationStatus = isRunning ? 'Status: Tracking (Background Core)' : 'Status: Stopped';
      });
    }
  }

  Future<bool> _requireAlwaysPermission() async {
    // We still use geolocator exactly as before solely to orchestrate the permission funnel
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationStatus = 'Status: Location Services disabled');
      return false;
    }

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        if (mounted) setState(() => _locationStatus = 'Status: Permission denied');
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      await geo.Geolocator.openAppSettings();
      if (mounted) setState(() => _locationStatus = 'Status: Permission denied forever');
      return false;
    }

    if (permission == geo.LocationPermission.whileInUse) {
      permission = await geo.Geolocator.requestPermission();
      if (permission != geo.LocationPermission.always) {
        if (mounted) setState(() => _locationStatus = 'Warning: Only got WhileInUse');
      }
    }

    return permission == geo.LocationPermission.always || permission == geo.LocationPermission.whileInUse;
  }

  Future<void> _startBackgroundTracking() async {
    bool hasPermission = await _requireAlwaysPermission();
    if (!hasPermission) return;

    setState(() {
      _isTracking = true;
      _locationStatus = 'Status: Tracking started (Headless Core)';
    });

    // Fire the heavy BackgroundLocator Registration
    await BackgroundLocator.registerLocationUpdate(
      locationCallback,
      initCallback: initCallback,
      disposeCallback: disposeCallback,
      iosSettings: IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 0,
        showsBackgroundLocationIndicator: true,
        stopWithTerminate: true,
        pausesLocationUpdatesAutomatically: false,
        activityType: LocationActivityType.other,
      ),
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 10, // Seconds
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Tracking Location in Background',
          notificationMsg: 'Your app is aggressively tracking location.',
          notificationBigMsg: 'App is surviving termination and doze states.',
          notificationIcon: '',
          notificationIconColor: Colors.blue,
          notificationTapCallback: notificationCallback,
        ),
        wakeLockTime: 20,
      ),
    );
  }

  Future<void> _stopTracking() async {
    await BackgroundLocator.unRegisterLocationUpdate();
    setState(() {
      _isTracking = false;
      _locationStatus = 'Status: Stopped explicitly';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isolate Background Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _locationStatus,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              _currentLocation,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isTracking ? _stopTracking : _startBackgroundTracking,
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? 'Stop Tracking' : 'Start Isolate Tracking'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
