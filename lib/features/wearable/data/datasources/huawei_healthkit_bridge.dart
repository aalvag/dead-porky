import 'dart:io';

import 'package:flutter/services.dart';

class HuaweiHealthKitException implements Exception {
  const HuaweiHealthKitException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'HuaweiHealthKitException($code): $message';
}

class HuaweiHealthKitSyncResult {
  const HuaweiHealthKitSyncResult({
    required this.steps,
    required this.sleepHours,
    required this.deepSleepHours,
    required this.lightSleepHours,
    required this.remSleepHours,
    required this.averageHeartRate,
    required this.restingHeartRate,
    required this.sourceLabel,
    required this.coverageNote,
    required this.availableMetricKeys,
  });

  final int steps;
  final double sleepHours;
  final double deepSleepHours;
  final double lightSleepHours;
  final double remSleepHours;
  final int averageHeartRate;
  final int restingHeartRate;
  final String sourceLabel;
  final String coverageNote;
  final List<String> availableMetricKeys;

  bool get hasAnyMetric =>
      steps > 0 ||
      sleepHours > 0 ||
      deepSleepHours > 0 ||
      lightSleepHours > 0 ||
      remSleepHours > 0 ||
      averageHeartRate > 0 ||
      restingHeartRate > 0;

  factory HuaweiHealthKitSyncResult.fromMap(Map<Object?, Object?> raw) {
    num numberValue(String key) {
      final value = raw[key];
      if (value is num) {
        return value;
      }
      if (value is String) {
        return num.tryParse(value) ?? 0;
      }
      return 0;
    }

    String stringValue(String key, String fallback) {
      final value = raw[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      return fallback;
    }

    final rawMetricKeys = raw['availableMetricKeys'];
    final availableMetricKeys = rawMetricKeys is List
        ? rawMetricKeys.map((entry) => entry.toString()).toList()
        : <String>[];

    return HuaweiHealthKitSyncResult(
      steps: numberValue('steps').round(),
      sleepHours: _normalizeHours(numberValue('sleepHours')),
      deepSleepHours: _normalizeHours(numberValue('deepSleepHours')),
      lightSleepHours: _normalizeHours(numberValue('lightSleepHours')),
      remSleepHours: _normalizeHours(numberValue('remSleepHours')),
      averageHeartRate: numberValue('averageHeartRate').round(),
      restingHeartRate: numberValue('restingHeartRate').round(),
      sourceLabel: stringValue('sourceLabel', 'Huawei Health Kit'),
      coverageNote: stringValue(
        'coverageNote',
        'Fuente actual: Huawei Health Kit.',
      ),
      availableMetricKeys: availableMetricKeys,
    );
  }

  static double _normalizeHours(num rawValue) {
    if (rawValue <= 0) {
      return 0;
    }

    final value = rawValue.toDouble();
    if (value > 1440) {
      return value / 3600000;
    }
    if (value > 24) {
      return value / 60;
    }
    return value;
  }
}

class HuaweiHealthKitBridge {
  HuaweiHealthKitBridge._();

  static final HuaweiHealthKitBridge instance = HuaweiHealthKitBridge._();
  static const MethodChannel _channel = MethodChannel(
    'com.deadporky.app/huawei_health_kit',
  );

  Future<HuaweiHealthKitSyncResult> syncTodayMetrics() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Huawei Health Kit solo esta disponible en Android.',
      );
    }

    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'syncTodayMetrics',
      );
      if (raw == null) {
        throw const HuaweiHealthKitException(
          code: 'empty_result',
          message: 'Huawei Health Kit no devolvio datos en la sync actual.',
        );
      }
      return HuaweiHealthKitSyncResult.fromMap(raw);
    } on PlatformException catch (error) {
      throw HuaweiHealthKitException(
        code: error.code,
        message: error.message ?? 'Fallo desconocido en Huawei Health Kit.',
        details: error.details,
      );
    }
  }
}