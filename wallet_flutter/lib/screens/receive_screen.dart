import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../rpc_client.dart';

class ReceiveScreen extends StatefulWidget {
  final RpcClient rpc;
  const ReceiveScreen({super.key, required this.rpc});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  String? _address;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() { _loading = true; _error = null; });
    try {
      final addr = await widget.rpc.getNewAddress();
      if (mounted) setState(() { _address = addr; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _copy() {
    if (_address == null) return;
    Clipboard.setData(ClipboardData(text: _address!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied!', style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF14F195).withOpacity(0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receive SHRD', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Share this address to receive ShardCoin',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 32),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF9945FF)))
          else if (_error != null)
            Column(
              children: [
                Text(_error!, style: GoogleFonts.inter(color: const Color(0xFFFF6B6B))),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadAddress,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9945FF)),
                  child: const Text('Retry')),
              ],
            )
          else if (_address != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: _address!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Address', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  SelectableText(
                    _address!,
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text('Copy Address', style: GoogleFonts.inter()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF14F195),
                      side: const BorderSide(color: Color(0xFF14F195)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadAddress,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('New Address', style: GoogleFonts.inter()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9945FF),
                      side: const BorderSide(color: Color(0xFF9945FF)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14F195).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF14F195).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF14F195), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Each transaction generates a new address for better privacy. Old addresses remain valid.',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
