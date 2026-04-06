import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../rpc_client.dart';

class SendScreen extends StatefulWidget {
  final RpcClient rpc;
  final VoidCallback onSent;

  const SendScreen({super.key, required this.rpc, required this.onSent});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  String? _txid;
  String? _error;
  double _estimatedFee = 0.0001;

  @override
  void initState() {
    super.initState();
    _loadFee();
  }

  Future<void> _loadFee() async {
    try {
      final fee = await widget.rpc.estimateSmartFee(6);
      if (mounted) setState(() => _estimatedFee = fee);
    } catch (_) {}
  }

  Future<void> _validateAddr() async {
    final addr = _addrCtrl.text.trim();
    if (addr.isEmpty) return;
    try {
      final result = await widget.rpc.validateAddress(addr);
      if (mounted && result['isvalid'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid ShardCoin address'), backgroundColor: Color(0xFFFF6B6B)));
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _sending = true; _txid = null; _error = null; });
    try {
      final txid = await widget.rpc.sendToAddress(
        _addrCtrl.text.trim(),
        double.parse(_amountCtrl.text),
        _commentCtrl.text,
      );
      if (mounted) {
        setState(() { _txid = txid; _sending = false; });
        _addrCtrl.clear();
        _amountCtrl.clear();
        _commentCtrl.clear();
        widget.onSent();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _sending = false; });
    }
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _amountCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send SHRD', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            _label('Recipient Address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addrCtrl,
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
              decoration: _inputDeco('S... or shrd1...'),
              onEditingComplete: _validateAddr,
              validator: (v) => v!.trim().isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 16),
            _label('Amount (SHRD)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('0.00000000'),
              validator: (v) {
                if (v!.isEmpty) return 'Amount required';
                if (double.tryParse(v) == null) return 'Invalid amount';
                if (double.parse(v) <= 0) return 'Amount must be positive';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text('Estimated fee: ${_estimatedFee.toStringAsFixed(8)} SHRD/kB',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            _label('Comment (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentCtrl,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: _inputDeco('Note for this transaction'),
            ),
            const SizedBox(height: 24),
            if (_txid != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14F195).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF14F195)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle, color: Color(0xFF14F195), size: 18),
                      const SizedBox(width: 8),
                      Text('Transaction Sent!', style: GoogleFonts.inter(color: const Color(0xFF14F195), fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    SelectableText(_txid!, style: GoogleFonts.jetBrainsMono(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6B6B)),
                ),
                child: Text(_error!, style: GoogleFonts.inter(color: const Color(0xFFFF6B6B))),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Sending...' : 'Send SHRD',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9945FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor: const Color(0xFF9945FF).withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: Colors.white24),
    filled: true,
    fillColor: const Color(0xFF1A1A2E),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF9945FF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
    ),
  );
}
