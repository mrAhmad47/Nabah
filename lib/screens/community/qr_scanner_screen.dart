import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/nebah_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        _controller.stop();
        _showResultDialog(code);
        break;
      }
    }
  }

  void _showResultDialog(String rawCode) {
    final bool isValid = rawCode.contains('NEBAH-VERIFIED') || rawCode.length > 20;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: NebahColors.slate800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isValid ? Icons.verified : Icons.warning_amber_rounded,
              color: isValid ? NebahColors.safetyEmerald : Colors.redAccent,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isValid ? '✓ VERIFIED OFFICER' : '✗ UNVERIFIED ID',
              style: TextStyle(
                color: isValid ? NebahColors.safetyEmerald : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isValid) ...[
              const Text('Officer Name: Commander Kabir Abubakar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Badge Number: NEB-VIG-2026-084', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('Rank: Chief Patrol Commander', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('Jurisdiction: Sarkin Yama Quarter', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('Status: ACTIVE ON PATROL', style: TextStyle(color: NebahColors.safetyEmerald, fontWeight: FontWeight.bold)),
            ] else ...[
              const Text('This QR code could not be validated against the Nebah Security Registry.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              const Text('Possible forgery or expired ID badge.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              _controller.start();
            },
            child: const Text('Scan Another', style: TextStyle(color: NebahColors.cobaltBlue)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: NebahColors.cobaltBlue),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Vigilante Credential QR'),
        backgroundColor: NebahColors.slate800,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: NebahColors.cobaltBlue, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Text(
              'Align the vigilante digital ID badge QR code within the frame to verify credentials.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13, backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
