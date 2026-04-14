import 'package:background_locator_neo/keys.dart';

import 'locator_settings.dart';

enum LocationActivityType {
  other,
  automotiveNavigation,
  fitness,
  otherNavigation,
  airborne,
}

extension LocationActivityTypeExtension on LocationActivityType {
  int get value {
    switch (this) {
      case LocationActivityType.other:
        return 1;
      case LocationActivityType.automotiveNavigation:
        return 2;
      case LocationActivityType.fitness:
        return 3;
      case LocationActivityType.otherNavigation:
        return 4;
      case LocationActivityType.airborne:
        return 5;
    }
  }
}

class IOSSettings extends LocatorSettings {
  final bool showsBackgroundLocationIndicator;
  final bool stopWithTerminate;
  final bool pausesLocationUpdatesAutomatically;
  final LocationActivityType activityType;

  const IOSSettings({
    LocationAccuracy accuracy = LocationAccuracy.NAVIGATION,
    double distanceFilter = 0,
    this.showsBackgroundLocationIndicator = false,
    this.stopWithTerminate = false,
    this.pausesLocationUpdatesAutomatically = true,
    this.activityType = LocationActivityType.other,
  }) : super(accuracy: accuracy, distanceFilter: distanceFilter);

  Map<String, dynamic> toMap() {
    return {
      Keys.SETTINGS_ACCURACY: accuracy.value,
      Keys.SETTINGS_DISTANCE_FILTER: distanceFilter,
      Keys.SETTINGS_IOS_SHOWS_BACKGROUND_LOCATION_INDICATOR:
          showsBackgroundLocationIndicator,
      Keys.SETTINGS_IOS_STOP_WITH_TERMINATE: stopWithTerminate,
      Keys.SETTINGS_IOS_PAUSES_LOCATION_UPDATES_AUTOMATICALLY:
          pausesLocationUpdatesAutomatically,
      Keys.SETTINGS_IOS_ACTIVITY_TYPE: activityType.value,
    };
  }
}
