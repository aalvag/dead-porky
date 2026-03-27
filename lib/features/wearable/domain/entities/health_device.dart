import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================== Entities ====================

class HealthDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final DateTime? lastSync;

  const HealthDevice({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.disconnected,
    this.lastSync,
  });

  HealthDevice copyWith({DeviceStatus? status, DateTime? lastSync}) {
    return HealthDevice(
      id: id,
      name: name,
      type: type,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
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

// ==================== Preset Devices ====================

class PresetDevices {
  static final List<HealthDevice> devices = [
    const HealthDevice(
      id: '1',
      name: 'Apple Watch Series 9',
      type: DeviceType.smartwatch,
    ),
    const HealthDevice(id: '2', name: 'Withings Body+', type: DeviceType.scale),
    const HealthDevice(
      id: '3',
      name: 'Dexcom G7',
      type: DeviceType.glucoseMonitor,
    ),
    const HealthDevice(
      id: '4',
      name: 'Omron Evolv',
      type: DeviceType.bloodPressure,
    ),
    const HealthDevice(
      id: '5',
      name: 'Fitbit Charge 6',
      type: DeviceType.fitnessBand,
    ),
    const HealthDevice(
      id: '6',
      name: 'Garmin Venu 3',
      type: DeviceType.smartwatch,
    ),
    const HealthDevice(
      id: '7',
      name: 'Mi Band 8',
      type: DeviceType.fitnessBand,
    ),
  ];
}
