import 'package:flutter/material.dart';

class FcmTokenCard extends StatelessWidget {
  final String token;

  const FcmTokenCard({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.vpn_key, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FCM Token (Truncated):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    token.isEmpty ? 'Mengambil FCM Token...' : token,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
