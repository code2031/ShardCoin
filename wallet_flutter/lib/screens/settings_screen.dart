import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../rpc_client.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onSaved;
  final bool isSetup;

  const SettingsScreen({
    super.key,
    required this.prefs,
    required this.onSaved,
    this.isSetup = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _walletCtrl;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: widget.prefs.getString('rpc_host') ?? '127.0.0.1');
    _portCtrl = TextEditingController(text: (widget.prefs.getInt('rpc_port') ?? 7332).toString());
    _userCtrl = TextEditingController(text: widget.prefs.getString('rpc_user') ?? 'shardcoin');
    _passCtrl = TextEditingController(text: widget.prefs.getString('rpc_pass') ?? '');
    _walletCtrl = TextEditingController(text: widget.prefs.getString('wallet_name') ?? 'default');
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _walletCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    final rpc = RpcClient(
      host: _hostCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text) ?? 7332,
      user: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );
    try {
      final info = await rpc.getBlockchainInfo();
      setState(() {
        _testOk = true;
        _testResult = 'Connected! Chain: ${info['chain']}, Blocks: ${info['blocks']}';
      });
    } catch (e) {
      setState(() {
        _testOk = false;
        _testResult = 'Failed: $e';
      });
    } finally {
      setState(() { _testing = false; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.prefs.setString('rpc_host', _hostCtrl.text.trim());
    await widget.prefs.setInt('rpc_port', int.tryParse(_portCtrl.text) ?? 7332);
    await widget.prefs.setString('rpc_user', _userCtrl.text.trim());
    await widget.prefs.setString('rpc_pass', _passCtrl.text);
    await widget.prefs.setString('wallet_name', _walletCtrl.text.trim());
    widget.onSaved();
    if (mounted && !widget.isSetup) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Text(
          widget.isSetup ? 'Connect to Node' : 'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: widget.isSetup ? null : const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isSetup) ...[
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                          ),
                        ),
                        child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 16),
                      Text('ShardCoin Wallet',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Connect to your ShardCoin node to get started',
                        style: GoogleFonts.inter(color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              _sectionLabel('Node RPC'),
              const SizedBox(height: 12),
              _field(_hostCtrl, 'Host', 'e.g. 127.0.0.1 or 192.168.1.100',
                validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _field(_portCtrl, 'Port', '7332',
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid port' : null),
              const SizedBox(height: 12),
              _field(_userCtrl, 'RPC Username', 'shardcoin'),
              const SizedBox(height: 12),
              _field(_passCtrl, 'RPC Password', 'from shardcoin.conf',
                obscure: true,
                validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 24),
              _sectionLabel('Wallet'),
              const SizedBox(height: 12),
              _field(_walletCtrl, 'Wallet Name', 'default'),
              const SizedBox(height: 8),
              Text('The wallet loaded in shardcoind (leave empty for default)',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 24),
              if (_testResult != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testOk ? const Color(0xFF14F195).withOpacity(0.1) : const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _testOk ? const Color(0xFF14F195) : const Color(0xFFFF6B6B), width: 1),
                  ),
                  child: Text(_testResult!,
                    style: GoogleFonts.inter(color: _testOk ? const Color(0xFF14F195) : const Color(0xFFFF6B6B), fontSize: 13)),
                ),
              if (_testResult != null) const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _testing ? null : _testConnection,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF9945FF)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _testing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Test Connection', style: GoogleFonts.inter(color: const Color(0xFF9945FF))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9945FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.isSetup ? 'Connect' : 'Save',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
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
                    Text('Setup Guide', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Add to ~/.shardcoin/shardcoin.conf:\n\nrpcuser=shardcoin\nrpcpassword=yourpassword\nrpcallowip=0.0.0.0/0\nrpcbind=0.0.0.0\nserver=1',
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF9945FF), letterSpacing: 0.5));

  Widget _field(TextEditingController ctrl, String label, String hint, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24),
        labelStyle: GoogleFonts.inter(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9945FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
      validator: validator,
    );
  }
}
