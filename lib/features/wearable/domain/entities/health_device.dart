import 'package:flutter/material.dart';

// ==================== Entities ====================

class HealthDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final DateTime? lastSync;
  final DeviceConnectionSource connectionSource;
  final String? bleDeviceId;
  final int? lastSeenRssi;

  const HealthDevice({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.disconnected,
    this.lastSync,
    this.connectionSource = DeviceConnectionSource.bluetooth,
    this.bleDeviceId,
    this.lastSeenRssi,
  });

  HealthDevice copyWith({
    DeviceStatus? status,
    DateTime? lastSync,
    DeviceConnectionSource? connectionSource,
    String? bleDeviceId,
    int? lastSeenRssi,
  }) {
    return HealthDevice(
      id: id,
      name: name,
      type: type,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      connectionSource: connectionSource ?? this.connectionSource,
      bleDeviceId: bleDeviceId ?? this.bleDeviceId,
      lastSeenRssi: lastSeenRssi ?? this.lastSeenRssi,
    );
  }

  static const String huaweiGt6ProId = 'huawei_gt6_pro';
  static const String huaweiGt6ProName = 'HUAWEI WATCH GT 6 Pro';

  static HealthDevice huaweiGt6Pro({
    DeviceStatus status = DeviceStatus.disconnected,
    DateTime? lastSync,
    DeviceConnectionSource connectionSource = DeviceConnectionSource.bluetooth,
    String? bleDeviceId,
    int? lastSeenRssi,
  }) {
    return HealthDevice(
      id: huaweiGt6ProId,
      name: huaweiGt6ProName,
      type: DeviceType.smartwatch,
      status: status,
      lastSync: lastSync,
      connectionSource: connectionSource,
      bleDeviceId: bleDeviceId,
      lastSeenRssi: lastSeenRssi,
    );
  }
}

enum DeviceType {
  smartwatch,
  scale,
  glucoseMonitor,
  bloodPressure,
  fitnessBand,
}

enum DeviceStatus { connected, disconnected, syncing }

enum DeviceConnectionSource { bluetooth, healthPlatform, hybrid }

extension DeviceTypeX on DeviceType {
  String get label {
    switch (this) {
      case DeviceType.smartwatch:
        return 'Smartwatch';
      case DeviceType.scale:
        return 'Báscula inteligente';
      case DeviceType.glucoseMonitor:
        return 'Monitor de glucosa';
      case DeviceType.bloodPressure:
        return 'Tensiómetro';
      case DeviceType.fitnessBand:
        return 'Pulsera fitness';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.smartwatch:
        return Icons.watch;
      case DeviceType.scale:
        return Icons.monitor_weight;
      case DeviceType.glucoseMonitor:
        return Icons.bloodtype;
      case DeviceType.bloodPressure:
        return Icons.favorite;
      case DeviceType.fitnessBand:
        return Icons.watch_outlined;
    }
  }
}

extension DeviceConnectionSourceX on DeviceConnectionSource {
  String get label {
    switch (this) {
      case DeviceConnectionSource.bluetooth:
        return 'BLE';
      case DeviceConnectionSource.healthPlatform:
        return 'Health Connect / Apple Health';
      case DeviceConnectionSource.hybrid:
        return 'BLE + Health Connect / Apple Health';
    }
  }
}
