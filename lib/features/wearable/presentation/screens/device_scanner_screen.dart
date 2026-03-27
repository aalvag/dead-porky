import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/wearable/domain/entities/health_device.dart';

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
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectedDevices = ref.watch(connectedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
            onPressed: _toggleScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connected devices
            if (connectedDevices.isNotEmpty) ...[
              Text(
                'Conectados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...connectedDevices.map(
                (device) => _DeviceCard(
                  device: device,
                  onDisconnect: () => _disconnectDevice(device),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Health sources info
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
                          'Fuentes de datos de salud',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.apple,
                      text: 'HealthKit (iOS) - Pasos, sueño, FC',
                    ),
                    _InfoRow(
                      icon: Icons.android,
                      text: 'Health Connect (Android) - Todos los datos',
                    ),
                    _InfoRow(
                      icon: Icons.bluetooth,
                      text: 'BLE - Básculas, monitores FC, glucosa',
                    ),
                    _InfoRow(
                      icon: Icons.cloud,
                      text: 'APIs - Fitbit, Garmin, Withings, Dexcom',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _toggleScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(
                  _isScanning ? 'Buscando...' : 'Buscar dispositivos',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Available devices (simulated)
            if (_isScanning) ...[
              Text(
                'Dispositivos encontrados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...PresetDevices.devices.map(
                (device) => _DeviceCard(
                  device: device,
                  onConnect: () => _connectDevice(device),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleScan() {
    setState(() => _isScanning = !_isScanning);
    if (_isScanning) {
      // Simulate scan
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isScanning) {
          // Keep scanning
        }
      });
    }
  }

  void _connectDevice(HealthDevice device) {
    final connected = List<HealthDevice>.from(
      ref.read(connectedDevicesProvider),
    );

    if (!connected.any((d) => d.id == device.id)) {
      connected.add(
        device.copyWith(
          status: DeviceStatus.connected,
          lastSync: DateTime.now(),
        ),
      );
      ref.read(connectedDevicesProvider.notifier).state = connected;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${device.name} conectado')));
    }
  }

  void _disconnectDevice(HealthDevice device) {
    final connected = List<HealthDevice>.from(
      ref.read(connectedDevicesProvider),
    );
    connected.removeWhere((d) => d.id == device.id);
    ref.read(connectedDevicesProvider.notifier).state = connected;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${device.name} desconectado')));
  }
}

// ==================== Widgets ====================

class _DeviceCard extends StatelessWidget {
  final HealthDevice device;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const _DeviceCard({required this.device, this.onConnect, this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = device.status == DeviceStatus.connected;

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
              ? 'Conectado · ${_formatLastSync(device.lastSync)}'
              : device.type.label,
        ),
        trailing: isConnected
            ? IconButton(
                icon: const Icon(Icons.link_off),
                onPressed: onDisconnect,
              )
            : FilledButton(onPressed: onConnect, child: const Text('Conectar')),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
