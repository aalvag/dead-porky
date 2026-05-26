import 'dart:async';
import 'dart:io';

import 'package:dead_porky/core/constants/app_constants.dart';
import 'package:dead_porky/features/wearable/domain/entities/health_device.dart';
import 'package:dead_porky/features/wearable/presentation/providers/wearable_metrics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ==================== Providers ====================

final connectedDevicesProvider = StateProvider<List<HealthDevice>>((ref) => []);

// ==================== Screen ====================

class DeviceScannerScreen extends ConsumerStatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  ConsumerState<DeviceScannerScreen> createState() =>
      _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends ConsumerState<DeviceScannerScreen> {
  static const Map<String, String> _knownGattServices = {
    '00001800-0000-1000-8000-00805f9b34fb': 'Generic Access',
    '00001801-0000-1000-8000-00805f9b34fb': 'Generic Attribute',
    '0000180a-0000-1000-8000-00805f9b34fb': 'Device Information',
    '0000180d-0000-1000-8000-00805f9b34fb': 'Heart Rate',
    '0000180f-0000-1000-8000-00805f9b34fb': 'Battery',
    '00001810-0000-1000-8000-00805f9b34fb': 'Blood Pressure',
    '00001814-0000-1000-8000-00805f9b34fb': 'Running Speed and Cadence',
    '00001816-0000-1000-8000-00805f9b34fb': 'Cycling Speed and Cadence',
    '0000181a-0000-1000-8000-00805f9b34fb': 'Environmental Sensing',
    '0000181c-0000-1000-8000-00805f9b34fb': 'User Data',
    '00001826-0000-1000-8000-00805f9b34fb': 'Fitness Machine',
  };

  bool _isScanning = false;
  bool _isConnecting = false;
  String? _scanError;
  String? _statusMessage;
  String? _connectionNote;
  String? _bleProbeSummary;
  String? _bleProbeDetails;
  List<HealthDevice> _scanCandidates = const [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    unawaited(FlutterBluePlus.stopScan());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final wearableMetrics = ref.watch(wearableMetricsProvider);
    final activeDevice = connectedDevices.isEmpty ? null : connectedDevices.first;
    final hasActiveDevice = activeDevice != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Huawei GT6 Pro'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
            onPressed: _isConnecting ? null : _toggleScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeDevice != null) ...[
              Text(
                'Conectado',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _DeviceCard(
                device: activeDevice,
                onDisconnect: () => _disconnectDevice(activeDevice),
              ),
              const SizedBox(height: 24),
            ],

            _buildCurrentStatusCard(
              theme,
              hasActiveDevice: hasActiveDevice,
              wearableMetrics: wearableMetrics,
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Que hace cada boton',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Probar conexion Bluetooth: revisa si el telefono puede hablar directo con el reloj.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Platform.isAndroid
                          ? '2. Actualizar datos de Huawei Health: primero intenta Huawei Health Kit y, si no esta disponible, usa Health Connect como respaldo.'
                          : '2. Actualizar datos de Apple Health: lee lo que ya este disponible en Apple Health.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Platform.isAndroid
                          ? '3. Si aqui solo aparecen pasos, el reloj esta enlazado, pero Huawei Health todavia no esta abriendo el resto de metricas ni por Health Kit ni por Health Connect.'
                          : '3. Si aqui faltan metricas, el reloj esta enlazado, pero Apple Health todavia no las esta recibiendo.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: wearableMetrics.isSyncing ? null : _syncHuaweiHealth,
                icon: wearableMetrics.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(_healthSyncButtonLabel(wearableMetrics)),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isConnecting ? null : _toggleScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(
                  _isScanning
                      ? 'Buscando reloj por Bluetooth...'
                      : 'Probar conexion Bluetooth',
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_bleProbeSummary != null) ...[
              _buildBleProbeCard(theme),
              const SizedBox(height: 16),
            ],

            if (_scanError != null || _statusMessage != null || _connectionNote != null)
              _StatusBanner(
                isError: _scanError != null,
                message: _scanError ?? _connectionNote ?? _statusMessage!,
              ),

            if (wearableMetrics.lastSyncedAt != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ultima sync: ${_formatTimestamp(wearableMetrics.lastSyncedAt!)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_isScanning || _scanCandidates.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Candidatos encontrados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._scanCandidates.map(
                (device) => _DeviceCard(
                  device: device,
                  isBusy: _isConnecting,
                  onConnect: () => _connectDevice(device),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _syncHuaweiHealth() async {
    final notifier = ref.read(wearableMetricsProvider.notifier);
    try {
      await notifier.syncWithHealthPlatform();
      _upsertHuaweiDevice(
        connectionSource: DeviceConnectionSource.healthPlatform,
        lastSync: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _connectionNote = null;
          _scanError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lectura de datos completada'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanError = '$e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo sincronizar Huawei Health: $e')),
        );
      }
    }
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await _stopScan(showMessage: true);
      return;
    }

    await _startHuaweiScan();
  }

  Future<void> _startHuaweiScan() async {
    setState(() {
      _isScanning = true;
      _scanError = null;
      _statusMessage = 'Buscando el reloj por BLE...';
      _connectionNote = null;
      _bleProbeSummary = null;
      _bleProbeDetails = null;
      _scanCandidates = const [];
    });

    try {
      await _ensureBluetoothReady();
      final knownCandidates = await _loadKnownHuaweiDevices();
      if (mounted && knownCandidates.isNotEmpty) {
        setState(() {
          _scanCandidates = knownCandidates;
          _statusMessage = knownCandidates.length == 1
              ? 'Reloj Huawei detectado entre los dispositivos vinculados del telefono.'
              : '${knownCandidates.length} dispositivos Huawei detectados entre los dispositivos vinculados del telefono.';
        });
      }

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          if (!mounted) {
            return;
          }

          final filtered = results
              .map(_toCandidateDevice)
              .whereType<HealthDevice>()
              .toList();
          final merged = _mergeCandidates(_scanCandidates, filtered);
          setState(() {
            _scanCandidates = merged;
            if (merged.isNotEmpty) {
              _statusMessage = merged.length == 1
                  ? 'Reloj Huawei detectado.'
                  : '${merged.length} relojes Huawei detectados.';
            }
          });
        },
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          setState(() {
            _scanError = 'Error durante el scan BLE: $error';
          });
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: AppConstants.bleScanTimeoutSeconds),
      );
      await FlutterBluePlus.isScanning.where((value) => value == false).first;

      if (mounted) {
        setState(() {
          _isScanning = false;
          if (_scanCandidates.isEmpty && _scanError == null) {
            _statusMessage = 'No encontré el reloj. Déjalo cerca, con Bluetooth activo y, si ya está emparejado con Android, revisa que siga vinculado en ajustes Bluetooth.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanError = 'No pude iniciar el scan BLE: $e';
        });
      }
    } finally {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
  }

  Future<List<HealthDevice>> _loadKnownHuaweiDevices() async {
    final candidates = <HealthDevice>[];
    final seenIds = <String>{};

    Future<void> addBluetoothDevice(BluetoothDevice device) async {
      final displayName = _candidateNameForDevice(device: device);
      if (displayName == null) {
        return;
      }

      final remoteId = device.remoteId.str;
      if (!seenIds.add(remoteId)) {
        return;
      }

      int? rssi;
      try {
        if (device.isConnected) {
          rssi = await device.readRssi();
        }
      } catch (_) {}

      candidates.add(
        HealthDevice(
          id: remoteId,
          name: displayName,
          type: DeviceType.smartwatch,
          bleDeviceId: remoteId,
          lastSeenRssi: rssi,
        ),
      );
    }

    if (Platform.isAndroid) {
      try {
        final bondedDevices = await FlutterBluePlus.bondedDevices;
        for (final device in bondedDevices) {
          await addBluetoothDevice(device);
        }
      } catch (e) {
        debugPrint('Bonded devices lookup failed: $e');
      }
    }

    try {
      final systemDevices = await FlutterBluePlus.systemDevices(
        [Guid(AppConstants.heartRateService)],
      );
      for (final device in systemDevices) {
        await addBluetoothDevice(device);
      }
    } catch (e) {
      debugPrint('System devices lookup failed: $e');
    }

    candidates.sort((left, right) {
      final leftRssi = left.lastSeenRssi ?? -999;
      final rightRssi = right.lastSeenRssi ?? -999;
      return rightRssi.compareTo(leftRssi);
    });
    return _prioritizeCandidates(candidates);
  }

  List<HealthDevice> _mergeCandidates(
    List<HealthDevice> base,
    List<HealthDevice> incoming,
  ) {
    final merged = <String, HealthDevice>{
      for (final device in base) device.id: device,
    };

    for (final device in incoming) {
      final previous = merged[device.id];
      merged[device.id] = previous == null
          ? device
          : previous.copyWith(
              bleDeviceId: device.bleDeviceId ?? previous.bleDeviceId,
              lastSeenRssi: device.lastSeenRssi ?? previous.lastSeenRssi,
            );
    }

    final output = merged.values.toList()
      ..sort((left, right) {
        final leftRssi = left.lastSeenRssi ?? -999;
        final rightRssi = right.lastSeenRssi ?? -999;
        return rightRssi.compareTo(leftRssi);
      });
    return _prioritizeCandidates(output);
  }

  Future<void> _stopScan({bool showMessage = false}) async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Stop scan failed: $e');
    }

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _isScanning = false;
      if (showMessage) {
        _statusMessage = 'Scan detenido.';
      }
    });
  }

  Future<void> _ensureBluetoothReady() async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      throw StateError('Este telefono no soporta Bluetooth Low Energy.');
    }

    if (Platform.isAndroid && FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    final adapterState = await FlutterBluePlus.adapterState.firstWhere(
      (state) => state != BluetoothAdapterState.unknown,
    );

    if (adapterState == BluetoothAdapterState.unauthorized) {
      throw StateError('Bluetooth sin permisos. Acepta los permisos de Bluetooth cuando el sistema los solicite.');
    }

    if (adapterState != BluetoothAdapterState.on) {
      throw StateError('Bluetooth apagado. Enciendelo para buscar el reloj.');
    }
  }

  bool _isHuaweiWatchName(String name) {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    if (normalizedName.isEmpty) {
      return false;
    }

    final looksLikeGt6 = _isTargetHuaweiWatchName(normalizedName);
    final looksLikeHuaweiWatch = normalizedName.contains('huawei') &&
        normalizedName.contains('watch') &&
        normalizedName.contains('gt');

    return looksLikeGt6 || looksLikeHuaweiWatch;
  }

  bool _isTargetHuaweiWatchName(String name) {
    final normalizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();

    return normalizedName.contains('gt 6 pro') ||
        normalizedName.contains('gt6 pro') ||
        normalizedName.contains('watch gt 6') ||
        normalizedName.contains('watch gt6') ||
        normalizedName.contains('huawei watch gt 6') ||
        normalizedName.contains('huawei watch gt6');
  }

  List<HealthDevice> _prioritizeCandidates(List<HealthDevice> candidates) {
    final targetMatches = candidates
        .where((device) => _isTargetHuaweiWatchName(device.name))
        .toList();

    return targetMatches.isNotEmpty ? targetMatches : candidates;
  }

  HealthDevice? _toCandidateDevice(ScanResult result) {
    final displayName = _candidateNameForDevice(
      device: result.device,
      advertisedName: result.advertisementData.advName,
    );
    if (displayName == null) {
      return null;
    }

    return HealthDevice(
      id: result.device.remoteId.str,
      name: displayName,
      type: DeviceType.smartwatch,
      bleDeviceId: result.device.remoteId.str,
      lastSeenRssi: result.rssi,
    );
  }

  String? _candidateNameForDevice({
    required BluetoothDevice device,
    String? advertisedName,
  }) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty && _isHuaweiWatchName(platformName)) {
      return platformName;
    }

    final trimmedAdvertisedName = advertisedName?.trim() ?? '';
    if (trimmedAdvertisedName.isNotEmpty &&
        _isHuaweiWatchName(trimmedAdvertisedName)) {
      return trimmedAdvertisedName;
    }

    return null;
  }

  String _normalizeUuid(String uuid) {
    return uuid.trim().toLowerCase();
  }

  bool _isStandardGattService(String uuid) {
    final normalizedUuid = _normalizeUuid(uuid);
    if (_knownGattServices.containsKey(normalizedUuid)) {
      return true;
    }

    return normalizedUuid.startsWith('0000') &&
        normalizedUuid.endsWith('-0000-1000-8000-00805f9b34fb');
  }

  String _describeGattService(BluetoothService service) {
    final normalizedUuid = _normalizeUuid(service.uuid.str);
    final serviceName = _knownGattServices[normalizedUuid];
    final characteristicCount = service.characteristics.length;
    final descriptor = serviceName ??
        (_isStandardGattService(normalizedUuid)
            ? 'Servicio GATT estandar'
            : 'Servicio propietario');

    return '$descriptor (${service.uuid.str}, chars: $characteristicCount)';
  }

  String _buildBleDiagnostics(List<BluetoothService> services) {
    if (services.isEmpty) {
      return 'Servicios detectados: 0. El reloj no expuso servicios GATT utilizables en esta sesion.';
    }

    final standardServices = services
        .where((service) => _isStandardGattService(service.uuid.str))
        .toList();
    final proprietaryServices = services.length - standardServices.length;
    final preview = services
        .take(4)
        .map(_describeGattService)
        .join(' | ');

    final extraCount = services.length - 4;
    final extraLabel = extraCount > 0 ? ' | +$extraCount servicios mas' : '';

    return 'Servicios detectados: ${services.length}. Estandar: ${standardServices.length}. '
        'Propietarios: $proprietaryServices. Vista rapida: $preview$extraLabel';
  }

  String _buildBleSummary(List<BluetoothService> services) {
    if (services.isEmpty) {
      return 'Bluetooth conectado, pero el reloj no mostro servicios BLE utilizables en esta sesion.';
    }

    final standardServices = services
        .where((service) => _isStandardGattService(service.uuid.str))
        .length;
    final proprietaryServices = services.length - standardServices;

    return 'Bluetooth conectado. El reloj mostro ${services.length} servicios BLE: '
        '$standardServices estandar y $proprietaryServices propietarios.';
  }

  String _healthPlatformName() {
    return Platform.isAndroid ? 'Huawei Health / Health Connect' : 'Apple Health';
  }

  String _healthSyncButtonLabel(WearableMetricsState wearableMetrics) {
    if (wearableMetrics.isSyncing) {
      return 'Leyendo datos de ${_healthPlatformName()}...';
    }

    if (wearableMetrics.lastSyncedAt == null) {
      return 'Dar permisos y leer datos';
    }

    return 'Actualizar datos de ${_healthPlatformName()}';
  }

  String _friendlySourceLabel(String sourceLabel) {
    final normalized = sourceLabel.toLowerCase();
    if (normalized.contains('sec.android.app.shealth') ||
        normalized.contains('samsung health')) {
      return 'Samsung Health';
    }
    if (normalized.contains('healthsync')) {
      return 'Health Sync';
    }
    if (normalized.contains('huawei')) {
      return 'Huawei Health';
    }
    return sourceLabel;
  }

  String _metricLabel(String metricKey) {
    switch (metricKey) {
      case 'steps':
        return 'pasos';
      case 'sleep':
        return 'sueno';
      case 'restingHeartRate':
        return 'FC en reposo';
      case 'averageHeartRate':
        return 'FC media';
      case 'activeMinutes':
        return 'minutos activos';
      case 'distanceKm':
        return 'distancia';
      case 'workoutsToday':
        return 'entrenamientos';
      case 'bloodOxygen':
        return 'SpO2';
      case 'respiratoryRate':
        return 'respiracion';
      case 'heartRateVariabilityMs':
        return 'HRV';
      default:
        return metricKey;
    }
  }

  String _healthDataStatusTitle(WearableMetricsState wearableMetrics) {
    if (wearableMetrics.availableMetricKeys.isEmpty) {
      return 'Aun no llegaron datos';
    }

    if (wearableMetrics.availableMetricKeys.length == 1 &&
        wearableMetrics.hasMetric('steps')) {
      return 'Solo llegaron pasos';
    }

    return 'Ya llegaron datos de salud';
  }

  String _healthDataStatusBody(WearableMetricsState wearableMetrics) {
    final source = wearableMetrics.healthSourceLabels.isEmpty
        ? _healthPlatformName()
        : _friendlySourceLabel(wearableMetrics.healthSourceLabels.first);

    if (wearableMetrics.availableMetricKeys.isEmpty) {
      return 'La app todavia no ve datos utilizables en ${_healthPlatformName()}. '
          'Toca el boton superior para volver a leerlos.';
    }

    if (wearableMetrics.availableMetricKeys.length == 1 &&
        wearableMetrics.hasMetric('steps')) {
      return 'Hoy ${_healthPlatformName()} solo esta recibiendo pasos desde $source. '
          'Sueno, FC y actividad todavia no llegaron.';
    }

    final visibleMetrics = wearableMetrics.availableMetricKeys
        .take(4)
        .map(_metricLabel)
        .join(', ');
    return 'Datos visibles ahora: $visibleMetrics. Fuente principal: $source.';
  }

  String _bluetoothStatusBody(bool hasActiveDevice) {
    if (hasActiveDevice) {
      return 'El reloj ya esta enlazado por Bluetooth con este telefono.';
    }

    return 'Todavia no hay una conexion Bluetooth activa con el reloj.';
  }

  Widget _buildBleProbeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bluetooth_searching, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ultima prueba Bluetooth directa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _bleProbeSummary!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_bleProbeDetails != null && _bleProbeDetails!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _bleProbeDetails!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(
    ThemeData theme, {
    required bool hasActiveDevice,
    required WearableMetricsState wearableMetrics,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Estado actual',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildStatusRow(
              theme,
              icon: hasActiveDevice
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              title: 'Bluetooth del reloj',
              status: hasActiveDevice ? 'Conectado' : 'No conectado',
              body: _bluetoothStatusBody(hasActiveDevice),
              accent: hasActiveDevice ? Colors.green : theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              theme,
              icon: Icons.monitor_heart_outlined,
              title: _healthPlatformName(),
              status: _healthDataStatusTitle(wearableMetrics),
              body: _healthDataStatusBody(wearableMetrics),
              accent: wearableMetrics.availableMetricKeys.isEmpty ||
                      (wearableMetrics.availableMetricKeys.length == 1 &&
                          wearableMetrics.hasMetric('steps'))
                  ? Colors.orange
                  : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String status,
    required String body,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectDevice(HealthDevice candidate) async {
    final bleDeviceId = candidate.bleDeviceId;
    if (bleDeviceId == null || bleDeviceId.isEmpty) {
      setState(() {
        _scanError = 'No pude obtener el identificador BLE del reloj.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _scanError = null;
      _connectionNote = null;
    });

    final device = BluetoothDevice.fromId(bleDeviceId);
    try {
      if (_isScanning) {
        await _stopScan();
      }

      final useAutoConnect = Platform.isAndroid;
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: AppConstants.bleConnectTimeoutSeconds),
        autoConnect: useAutoConnect,
        mtu: useAutoConnect ? null : 512,
      );

      if (useAutoConnect && !device.isConnected) {
        final state = await device.connectionState
            .where(
              (entry) =>
                  entry == BluetoothConnectionState.connected ||
                  entry == BluetoothConnectionState.disconnected,
            )
            .first
            .timeout(
              const Duration(seconds: AppConstants.bleConnectTimeoutSeconds),
            );

        if (state != BluetoothConnectionState.connected && !device.isConnected) {
          throw TimeoutException('No se abrio una sesion BLE util antes del timeout.');
        }
      }

      final services = await device.discoverServices();
      final bleDiagnostics = _buildBleDiagnostics(services);
      final bleSummary = _buildBleSummary(services);
      debugPrint('BLE diagnostics for ${candidate.name}: $bleDiagnostics');

      _upsertHuaweiDevice(
        connectionSource: DeviceConnectionSource.bluetooth,
        bleDeviceId: device.remoteId.str,
        lastSeenRssi: candidate.lastSeenRssi,
        lastSync: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _connectionNote = null;
          _bleProbeSummary = bleSummary;
          _bleProbeDetails = bleDiagnostics;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${candidate.name} conectado por BLE'),
          ),
        );
      }
    } catch (e) {
      try {
        await device.disconnect(queue: false);
      } catch (_) {}

      final linkedViaSystemPairing = await _linkViaSystemPairing(
        candidate,
        directBleError: e,
      );
      if (linkedViaSystemPairing) {
        return;
      }

      if (mounted) {
        setState(() {
          _scanError = 'No pude conectar con el reloj: $e';
          _bleProbeSummary = 'No se pudo completar la prueba Bluetooth directa.';
          _bleProbeDetails = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<bool> _linkViaSystemPairing(
    HealthDevice candidate, {
    Object? directBleError,
  }) async {
    if (!Platform.isAndroid) {
      return false;
    }

    final knownDevices = await _loadKnownHuaweiDevices();
    HealthDevice? pairedMatch;
    for (final device in knownDevices) {
      if (device.bleDeviceId == candidate.bleDeviceId) {
        pairedMatch = device;
        break;
      }
    }

    if (pairedMatch == null) {
      return false;
    }

    _upsertHuaweiDevice(
      connectionSource: DeviceConnectionSource.hybrid,
      bleDeviceId: pairedMatch.bleDeviceId,
      lastSeenRssi: candidate.lastSeenRssi ?? pairedMatch.lastSeenRssi,
      lastSync: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _scanError = null;
        _connectionNote = null;
        _bleProbeSummary = 'No se pudo abrir una sesion Bluetooth directa.';
        _bleProbeDetails = [
          'El reloj ya estaba enlazado con el telefono, asi que la app uso el emparejamiento del sistema.',
          if (directBleError != null) 'Fallo BLE directo: $directBleError',
          'Esto no demuestra que servicios BLE expone el reloj.',
          'Si quieres una prueba limpia, desvincula temporalmente el reloj de los ajustes Bluetooth de Android y vuelve a intentar.',
        ].join(' ');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${candidate.name} enlazado usando el emparejamiento del sistema'),
        ),
      );
    }

    return true;
  }

  Future<void> _disconnectDevice(HealthDevice device) async {
    final bleDeviceId = device.bleDeviceId;
    if (bleDeviceId != null && bleDeviceId.isNotEmpty) {
      try {
        await BluetoothDevice.fromId(bleDeviceId).disconnect(queue: false);
      } catch (e) {
        debugPrint('BLE disconnect failed: $e');
      }
    }

    final connected = List<HealthDevice>.from(ref.read(connectedDevicesProvider))
      ..removeWhere((entry) => entry.id == device.id);
    ref.read(connectedDevicesProvider.notifier).state = connected;
    ref
        .read(wearableMetricsProvider.notifier)
        .setConnectedDevices(connected.map((entry) => entry.name).toList());

    if (mounted) {
      setState(() {
        _connectionNote = 'Reloj desconectado.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${device.name} desconectado')),
      );
    }
  }

  void _upsertHuaweiDevice({
    required DeviceConnectionSource connectionSource,
    String? bleDeviceId,
    int? lastSeenRssi,
    DateTime? lastSync,
  }) {
    final connected = List<HealthDevice>.from(ref.read(connectedDevicesProvider));
    final index = connected.indexWhere(
      (device) => device.id == HealthDevice.huaweiGt6ProId,
    );
    final existing = index == -1 ? null : connected[index];
    final nextDevice = (existing ?? HealthDevice.huaweiGt6Pro()).copyWith(
      status: DeviceStatus.connected,
      lastSync: lastSync ?? DateTime.now(),
      connectionSource: _mergeSources(existing?.connectionSource, connectionSource),
      bleDeviceId: bleDeviceId ?? existing?.bleDeviceId,
      lastSeenRssi: lastSeenRssi ?? existing?.lastSeenRssi,
    );

    if (index == -1) {
      connected.add(nextDevice);
    } else {
      connected[index] = nextDevice;
    }

    ref.read(connectedDevicesProvider.notifier).state = connected;
    ref
        .read(wearableMetricsProvider.notifier)
        .setConnectedDevices(connected.map((entry) => entry.name).toList());
  }

  DeviceConnectionSource _mergeSources(
    DeviceConnectionSource? existing,
    DeviceConnectionSource incoming,
  ) {
    if (existing == null || existing == incoming) {
      return incoming;
    }

    return DeviceConnectionSource.hybrid;
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'justo ahora';
    }
    if (diff.inHours < 1) {
      return 'hace ${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return 'hace ${diff.inHours} h';
    }
    return 'hace ${diff.inDays} d';
  }
}

// ==================== Widgets ====================

class _DeviceCard extends StatelessWidget {
  final HealthDevice device;
  final bool isBusy;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const _DeviceCard({
    required this.device,
    this.isBusy = false,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = device.status == DeviceStatus.connected;
    final connectionSourceLabel = _connectionSourceLabel(device.connectionSource);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected
              ? Colors.green.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            device.type.icon,
            color: isConnected ? Colors.green : null,
          ),
        ),
        title: Text(device.name),
        subtitle: Text(
          isConnected
              ? '$connectionSourceLabel · ${_formatLastSync(device.lastSync)}'
              : device.lastSeenRssi != null
                  ? 'Senal ${device.lastSeenRssi} dBm'
                  : device.type.label,
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.link_off),
                onPressed: onDisconnect,
              )
            : FilledButton(
                onPressed: isBusy ? null : onConnect,
                child: Text(isBusy ? 'Conectando...' : 'Conectar'),
              ),
      ),
    );
  }

  String _connectionSourceLabel(DeviceConnectionSource source) {
    switch (source) {
      case DeviceConnectionSource.bluetooth:
        return 'Bluetooth conectado';
      case DeviceConnectionSource.healthPlatform:
        return Platform.isAndroid
            ? 'Datos por Huawei Health / Health Connect'
            : 'Datos por Apple Health';
      case DeviceConnectionSource.hybrid:
        return Platform.isAndroid
            ? 'Bluetooth + datos por Huawei Health / Health Connect'
            : 'Bluetooth + datos por Apple Health';
    }
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Nunca';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isError;
  final String message;

  const _StatusBanner({required this.isError, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isError
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 20,
            color: isError
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
