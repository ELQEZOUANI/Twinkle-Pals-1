import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum TrackingPermissionStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  unavailable,
}

abstract class TrackingPermission {
  Future<TrackingPermissionStatus> status();
  Future<TrackingPermissionStatus> request();
}

class IosTrackingPermission implements TrackingPermission {
  static const _channel = MethodChannel('twinkle_pals/tracking');

  @override
  Future<TrackingPermissionStatus> status() => _invoke('status');

  @override
  Future<TrackingPermissionStatus> request() => _invoke('request');

  Future<TrackingPermissionStatus> _invoke(String method) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return TrackingPermissionStatus.unavailable;
    }
    try {
      final value = await _channel.invokeMethod<String>(method);
      return TrackingPermissionStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => TrackingPermissionStatus.unavailable,
      );
    } on PlatformException {
      return TrackingPermissionStatus.unavailable;
    } on MissingPluginException {
      return TrackingPermissionStatus.unavailable;
    }
  }
}
