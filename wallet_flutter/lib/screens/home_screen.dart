import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../rpc_client.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final RpcClient rpc;
  final SharedPreferences prefs;
  final VoidCallback onDisconnect;

  const HomeScreen({
    super.key,
    required this.rpc,
    required this.prefs,
    required this.onDisconnect,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _balance;
  Map<String, dynamic>? _chainInfo;
  List<Map<String, dynamic>> _txs = [];
  bool _loading = true;
  String? _error;
  String _walletName = '';
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _walletName = widget.prefs.getString('wallet_name') ?? 'default';
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load or create wallet
      final wallets = await widget.rpc.listWallets();
      if (!wallets.contains(_walletName)) {
        try {
          await widget.rpc.loadWallet(_walletName);
        } catch (_) {
          await widget.rpc.createWallet(_walletName);
        }
      }
      final balance = await widget.rpc.getBalance();
      final chain = await widget.rpc.getBlockchainInfo();
      final txs = await widget.rpc.listTransactions(count: 10);
      if (mounted) {
        setState(() {
          _balance = balance;
          _chainInfo = chain;
          _txs = txs.reversed.toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _dashboardScreen(),
      TransactionsScreen(rpc: widget.rpc, onRefresh: _load),
      SendScreen(rpc: widget.rpc, onSent: _load),
      ReceiveScreen(rpc: widget.rpc),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
              ),
              child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('ShardCoin', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SettingsScreen(prefs: widget.prefs, onSaved: widget.onDisconnect),
            )),
          ),
        ],
      ),
      body: screens[_navIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF9945FF).withOpacity(0.2),
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFF9945FF)), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history, color: Color(0xFF9945FF)), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.send_outlined), selectedIcon: Icon(Icons.send, color: Color(0xFF9945FF)), label: 'Send'),
          NavigationDestination(icon: Icon(Icons.qr_code_outlined), selectedIcon: Icon(Icons.qr_code, color: Color(0xFF9945FF)), label: 'Receive'),
        ],
      ),
    );
  }

  Widget _dashboardScreen() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9945FF)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
              const SizedBox(height: 16),
              Text('Connection Error', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9945FF)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF9945FF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _balanceCard(),
            const SizedBox(height: 20),
            _networkCard(),
            const SizedBox(height: 20),
            _recentTxs(),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A3E), Color(0xFF0A2A1A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9945FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Balance', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${_balance?.toStringAsFixed(8) ?? '0.00000000'} SHRD',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Wallet: $_walletName', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _actionBtn('Send', Icons.send, const Color(0xFF9945FF), () {
                  setState(() => _navIndex = 2);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn('Receive', Icons.qr_code, const Color(0xFF14F195), () {
                  setState(() => _navIndex = 3);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _networkCard() {
    final blocks = _chainInfo?['blocks'] ?? 0;
    final chain = _chainInfo?['chain'] ?? '-';
    final difficulty = _chainInfo?['difficulty'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Network', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat('Blocks', '$blocks')),
              Expanded(child: _stat('Chain', chain)),
              Expanded(child: _stat('Difficulty', difficulty.toStringAsFixed(2))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _recentTxs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
            TextButton(
              onPressed: () => setState(() => _navIndex = 1),
              child: Text('See all', style: GoogleFonts.inter(color: const Color(0xFF9945FF), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_txs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('No transactions yet', style: GoogleFonts.inter(color: Colors.white38))),
          )
        else
          ...(_txs.take(5).map((tx) => _txTile(tx))),
      ],
    );
  }

  Widget _txTile(Map<String, dynamic> tx) {
    final category = tx['category'] ?? '';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final isSend = category == 'send';
    final color = isSend ? const Color(0xFFFF6B6B) : const Color(0xFF14F195);
    final sign = isSend ? '-' : '+';
    final address = tx['address'] ?? 'Unknown';
    final shortAddr = address.length > 16 ? '${address.substring(0, 8)}...${address.substring(address.length - 8)}' : address;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(isSend ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isSend ? 'Sent' : 'Received', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(shortAddr, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text('$sign${amount.abs().toStringAsFixed(4)} SHRD',
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
