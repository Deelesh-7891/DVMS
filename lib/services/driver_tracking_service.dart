// Live location for the Driver role.
//
// The guard logs the vehicle OUT at the gate and picks this driver, which
// opens a trip on the server. While GET /driver/trip/current returns a trip,
// GPS points stream to POST /driver/trip/{id}/pings — queued on the phone
// when offline. On gate-in the server answers 410 and tracking stops, so the
// driver is never followed off duty.
//
// Usage: DriverTracker.instance.start() on the Driver home screen,
//        DriverTracker.instance.checkNow() when the app resumes,
//        DriverTracker.instance.stop() on logout.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Same server as the rest of the app.
String get kApiBase => AuthService.baseUrl;

enum TrackerState { idle, noDriverLink, permissionNeeded, tracking, error }

class TrackerStatus {
  final TrackerState state;
  final String message;
  final String? vehicle; // e.g. "RJ14AB1234 · Swift"
  final DateTime? since;
  final int queued; // points waiting for network
  const TrackerStatus(
    this.state,
    this.message, {
    this.vehicle,
    this.since,
    this.queued = 0,
  });
}

class DriverTracker {
  DriverTracker._();

  /// One tracker for the whole app, so leaving and re-opening the Driver
  /// home screen never starts a second GPS stream.
  static final DriverTracker instance = DriverTracker._();

  String _token = '';
  final ValueNotifier<TrackerStatus> status = ValueNotifier(
    const TrackerStatus(TrackerState.idle, 'Not on a trip'),
  );

  static const _queueKey = 'dvms_ping_queue';
  static const _maxQueue = 5000; // ~40 h at 30 s — plenty for a trip offline
  static const _batchSize = 200;

  int? _tripId;
  Duration _pingInterval = const Duration(seconds: 30);
  int _minDistanceM = 25;
  StreamSubscription<Position>? _posSub;
  Timer? _pollTimer;
  Timer? _flushTimer;
  bool _flushing = false;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  /// Starts watching for trips. Safe to call more than once.
  Future<void> start() async {
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => checkNow(),
    );
    await checkNow();
  }

  /// Asks the server whether a trip is open, and starts/stops tracking to match.
  Future<void> checkNow() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    if (_token.isEmpty) return;
    try {
      final res = await http
          .get(Uri.parse('$kApiBase/driver/trip/current'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        _set(TrackerState.error, 'Server error ${res.statusCode}');
        return;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['driver'] == null) {
        await _stopStream();
        _set(
          TrackerState.noDriverLink,
          body['message']?.toString() ?? 'Login not linked to a driver',
        );
        return;
      }
      _pingInterval = Duration(
        seconds: (body['pingIntervalSec'] as num?)?.toInt() ?? 30,
      );
      _minDistanceM = (body['minDistanceM'] as num?)?.toInt() ?? 25;
      final trip = body['data'] as Map<String, dynamic>?;
      if (trip == null) {
        await _stopStream();
        await _flush(); // send anything left from the last trip
        _set(TrackerState.idle, 'Not on a trip');
        return;
      }
      final id = (trip['TripId'] as num).toInt();
      final vehicle = '${trip['RegistrationNo']} · ${trip['Model'] ?? ''}';
      final since = DateTime.tryParse(trip['StartedAt']?.toString() ?? '');
      if (_tripId != id || _posSub == null) {
        _tripId = id;
        final ok = await _startStream();
        if (!ok) return;
      }
      _set(
        TrackerState.tracking,
        'Sharing location',
        vehicle: vehicle,
        since: since,
      );
    } catch (e) {
      // Offline: keep whatever is running; points queue locally.
      if (_posSub == null)
        _set(TrackerState.error, 'No connection — will retry');
    }
  }

  Future<bool> _startStream() async {
    await _stopStream();
    if (!await Geolocator.isLocationServiceEnabled()) {
      _set(TrackerState.permissionNeeded, 'Turn on phone Location (GPS)');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _set(
        TrackerState.permissionNeeded,
        'Allow location for DVMS in phone Settings',
      );
      return false;
    }
    // "While in use" still works with the foreground notification on Android,
    // but "Allow all the time" survives the app being swiped away.
    if (perm == LocationPermission.whileInUse) {
      await Geolocator.requestPermission();
    }

    late LocationSettings settings;
    if (kIsWeb) {
      settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minDistanceM,
      );
    } else if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minDistanceM,
        intervalDuration: _pingInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'DVMS trip in progress',
          notificationText:
              'Your location is shared with the company until the vehicle is back at the gate.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minDistanceM,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minDistanceM,
      );
    }

    _posSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (e) => _set(TrackerState.error, 'GPS error: $e'),
    );
    _flushTimer ??= Timer.periodic(_pingInterval, (_) => _flush());
    return true;
  }

  Future<void> _stopStream() async {
    await _posSub?.cancel();
    _posSub = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  Future<void> _onPosition(Position p) async {
    if (_tripId == null) return;
    await _enqueue({
      'tripId': _tripId,
      'lat': p.latitude,
      'lng': p.longitude,
      'accuracy': p.accuracy,
      'speed': p.speed, // m/s — the server converts to km/h
      'heading': p.heading,
      'time': p.timestamp.toUtc().toIso8601String(),
    });
  }

  Future<void> _enqueue(Map<String, dynamic> point) async {
    final prefs = await SharedPreferences.getInstance();
    final q = prefs.getStringList(_queueKey) ?? <String>[];
    q.add(jsonEncode(point));
    if (q.length > _maxQueue) q.removeRange(0, q.length - _maxQueue);
    await prefs.setStringList(_queueKey, q);
    _refreshQueued(q.length);
  }

  /// Sends queued points, oldest first, grouped by trip.
  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      var q = prefs.getStringList(_queueKey) ?? <String>[];
      while (q.isNotEmpty) {
        final batch = q
            .take(_batchSize)
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        final tripId = batch.first['tripId'];
        final sameTrip = batch.takeWhile((p) => p['tripId'] == tripId).toList();
        final res = await http
            .post(
              Uri.parse('$kApiBase/driver/trip/$tripId/pings'),
              headers: _headers,
              body: jsonEncode({'points': sameTrip}),
            )
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 ||
            res.statusCode == 404 ||
            res.statusCode == 410) {
          // 404/410: trip gone or closed — those points can never be stored, drop them.
          q = q.sublist(sameTrip.length);
          await prefs.setStringList(_queueKey, q);
          if (res.statusCode == 410 && tripId == _tripId) {
            _tripId = null;
            await _stopStream();
            _set(TrackerState.idle, 'Trip ended — vehicle is back');
          }
        } else {
          break; // server/network trouble: retry next tick
        }
      }
      _refreshQueued(q.length);
    } catch (_) {
      // Offline — keep the queue for the next tick.
    } finally {
      _flushing = false;
    }
  }

  void _refreshQueued(int n) {
    final s = status.value;
    status.value = TrackerStatus(
      s.state,
      s.message,
      vehicle: s.vehicle,
      since: s.since,
      queued: n,
    );
  }

  void _set(TrackerState st, String msg, {String? vehicle, DateTime? since}) {
    status.value = TrackerStatus(
      st,
      msg,
      vehicle: vehicle,
      since: since,
      queued: status.value.queued,
    );
  }

  /// Call on logout: stops the GPS stream and the trip polling.
  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _tripId = null;
    await _stopStream();
    _set(TrackerState.idle, 'Not on a trip');
  }
}
