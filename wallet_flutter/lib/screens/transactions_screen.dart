import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../rpc_client.dart';

class TransactionsScreen extends StatefulWidget {
  final RpcClient rpc;
  final VoidCallback onRefresh;

  const TransactionsScreen({super.key, required this.rpc, required this.onRefresh});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _txs = [];
  bool _loading = true;
  String? _error;
  int _count = 25;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final txs = await widget.rpc.listTransactions(count: _count);
      if (mounted) setState(() { _txs = txs.reversed.toList(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF9945FF),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9945FF)))
          : _error != null
              ? Center(child: Text(_error!, style: GoogleFonts.inter(color: const Color(0xFFFF6B6B))))
              : _txs.isEmpty
                  ? Center(child: Text('No transactions', style: GoogleFonts.inter(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _txs.length + (_txs.length >= _count ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == _txs.length) {
                          return TextButton(
                            onPressed: () { setState(() => _count += 25); _load(); },
                            child: Text('Load more', style: GoogleFonts.inter(color: const Color(0xFF9945FF))),
                          );
                        }
                        return _txCard(_txs[i]);
                      },
                    ),
    );
  }

  Widget _txCard(Map<String, dynamic> tx) {
    final category = tx['category'] ?? '';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final isSend = category == 'send';
    final isGenerate = category == 'generate' || category == 'immature';
    final color = isSend
        ? const Color(0xFFFF6B6B)
        : isGenerate ? const Color(0xFFFFB347) : const Color(0xFF14F195);
    final sign = isSend ? '-' : '+';
    final address = tx['address'] ?? 'Coinbase';
    final txid = tx['txid'] ?? '';
    final confirmations = tx['confirmations'] ?? 0;
    final time = tx['time'] != null
        ? DateFormat('MMM d, yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(tx['time'] * 1000))
        : '-';
    final label = isGenerate ? 'Mining Reward' : (isSend ? 'Sent' : 'Received');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
          child: Icon(
            isGenerate ? Icons.star : (isSend ? Icons.arrow_upward : Icons.arrow_downward),
            color: color, size: 18,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            Text('$sign${amount.abs().toStringAsFixed(4)} SHRD',
              style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Text(time, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white12),
                _detail('Address', address, selectable: true),
                _detail('TXID', txid.isEmpty ? '-' : txid, selectable: true, mono: true),
                _detail('Confirmations', '$confirmations'),
                _detail('Amount', '${amount.abs().toStringAsFixed(8)} SHRD'),
                if (tx['fee'] != null)
                  _detail('Fee', '${((tx['fee'] as num).toDouble()).abs().toStringAsFixed(8)} SHRD'),
                if (txid.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => Clipboard.setData(ClipboardData(text: txid)),
                      icon: const Icon(Icons.copy, size: 14),
                      label: Text('Copy TXID', style: GoogleFonts.inter(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, {bool selectable = false, bool mono = false}) {
    final style = mono
        ? GoogleFonts.jetBrainsMono(color: Colors.white60, fontSize: 11)
        : GoogleFonts.inter(color: Colors.white70, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12))),
          Expanded(
            child: selectable
                ? SelectableText(value, style: style)
                : Text(value, style: style),
          ),
        ],
      ),
    );
  }
}
