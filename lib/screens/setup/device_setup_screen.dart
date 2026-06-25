import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:poultri_sense/providers/device_provider.dart';

class DeviceSetupScreen extends ConsumerStatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  ConsumerState<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends ConsumerState<DeviceSetupScreen> {
  final _textController = TextEditingController();
  final _deviceIdRegex = RegExp(
    r'^esp32_[A-Fa-f0-9]{6}$',
    caseSensitive: false,
  );

  bool _cameraGranted = false;
  bool _scannerOpen = false;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (mounted) setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _requestCameraAndOpenScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _cameraGranted = true;
        _scannerOpen = true;
        _error = null;
      });
    } else {
      setState(
        () => _error = 'Camera permission denied — use manual entry below.',
      );
    }
  }

  void _onQrDetected(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null) return;
    if (_deviceIdRegex.hasMatch(value)) {
      _saveDeviceId(value);
    } else {
      setState(() {
        _scannerOpen = false;
        _error = 'QR code is not a valid device ID. Try manual entry.';
      });
    }
  }

  Future<void> _confirmManualEntry() async {
    final value = _textController.text.trim();
    if (!_deviceIdRegex.hasMatch(value)) {
      setState(() => _error = 'Invalid format — expected: esp32_AABBCC');
      return;
    }
    await _saveDeviceId(value);
  }

  Future<void> _saveDeviceId(String id) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(deviceProvider.notifier).setDeviceId(id);
    if (mounted) context.go('/shell/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Connect Your Device')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── QR Scanner Section ─────────────────────────────────────
            if (_scannerOpen) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: screenWidth * 0.88,
                  height: screenWidth * 0.88,
                  child: MobileScanner(onDetect: _onQrDetected),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextButton(
                onPressed: () => setState(() => _scannerOpen = false),
                child: const Text('Cancel scan'),
              ),
            ] else ...[
              if (_cameraGranted)
                ElevatedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _scannerOpen = true;
                          _error = null;
                        }),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _saving ? null : _requestCameraAndOpenScanner,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Enable Camera & Scan'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                ),
            ],

            // ── Divider ────────────────────────────────────────────────
            SizedBox(height: screenHeight * 0.03),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  child: Text(
                    'or enter manually',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),

            // ── Manual Entry ───────────────────────────────────────────
            TextField(
              controller: _textController,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText: 'esp32_AABBCC',
                labelText: 'Device ID',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onSubmitted: (_) => _confirmManualEntry(),
            ),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: _saving ? null : _confirmManualEntry,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm'),
            ),

            // ── Help text ──────────────────────────────────────────────
            SizedBox(height: screenHeight * 0.04),
            Text(
              'The device ID is printed on the label affixed to the enclosure. '
              'It looks like: esp32_AABBCC',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
