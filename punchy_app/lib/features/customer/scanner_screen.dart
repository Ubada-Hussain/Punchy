import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 150,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Scanner integration pending.\n(Requires mobile_scanner package)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Mock a successful scan
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mock QR Scan: Card Punched!')),
                );
                context.pop();
              },
              child: const Text('Mock Successful Scan'),
            )
          ],
        ),
      ),
    );
  }
}
