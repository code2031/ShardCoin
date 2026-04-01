import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as jsu;

void _openUrl(String url) {
  js.globalContext.callMethod('open'.toJS, url.toJS, '_blank'.toJS);
}

void main() => runApp(const ExplorerApp());

// ===== COLORS =====
class C {
  static const bg   = Color(0xFF050508);
  static const bg2  = Color(0xFF0B0B10);
  static const card = Color(0xFF101018);
  static const card2= Color(0xFF161622);
  static const line = Color(0xFF1E1E30);
  static const line2= Color(0xFF2A2A40);
  static const t1   = Color(0xFFF4F4F8);
  static const t2   = Color(0xFFA8A8BC);
  static const t3   = Color(0xFF68687E);
  static const green= Color(0xFF14F195);
  static const purple=Color(0xFF9945FF);
  static const blue = Color(0xFF4DA2FF);
  static const pink = Color(0xFFEB459E);
}

// ===== APP =====
class ExplorerApp extends StatelessWidget {
  const ExplorerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ShardCoin Explorer',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: C.bg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    ),
    home: const Explorer(),
  );
}

// ===== EXPLORER =====
class Explorer extends StatefulWidget {
  const Explorer({super.key});
  @override
  State<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends State<Explorer> {
  // State
  List<dynamic> blocks = [];
  Map<String, dynamic>? info, blk, txn, addr;
  Map<String, dynamic>? aiNetwork, aiMempool, aiBlockAnalysis;
  Map<String, dynamic>? aiFee;
  bool loading = true;
  bool aiLoading = false;
  String? error;
  final sc = TextEditingController();
  Timer? timer;

  // View stack for back navigation
  final List<String> _history = ['home'];

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (blk == null && txn == null) _load();
    });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  void _push(String view) => _history.add(view);
  void _pop() {
    if (_history.length > 1) _history.removeLast();
    final last = _history.last;
    if (last == 'home') { _load(); }
  }

  Future<void> _load() async {
    try {
      final r1 = await http.get(Uri.parse('http://node.local:4402/api/info'));
      final r2 = await http.get(Uri.parse('http://node.local:4402/api/blocks'));
      if (mounted) setState(() {
        info = json.decode(r1.body);
        blocks = json.decode(r2.body);
        loading = false; error = null; blk = null; txn = null;
        aiBlockAnalysis = null;
        _history.clear(); _history.add('home');
      });
      // Auto-fetch AI insights in background
      _loadAiInsights();
    } catch (e) {
      if (mounted) setState(() { loading = false; error = 'Could not connect to node'; });
    }
  }

  Future<void> _loadAiInsights() async {
    if (info?['ai']?['enabled'] != true || info?['ai']?['ollama_connected'] != true) return;
    if (aiLoading) return;
    setState(() => aiLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('http://node.local:4402/api/ai/network')),
        http.get(Uri.parse('http://node.local:4402/api/ai/mempool')),
        http.get(Uri.parse('http://node.local:4402/api/ai/fee?urgency=normal')),
      ]);
      if (mounted) setState(() {
        aiNetwork = json.decode(results[0].body);
        aiMempool = json.decode(results[1].body);
        aiFee = json.decode(results[2].body);
        aiLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => aiLoading = false);
    }
  }

  Future<void> _loadBlockAi(String hash) async {
    try {
      final r = await http.get(Uri.parse('http://node.local:4402/api/ai/block/$hash'));
      if (mounted) setState(() => aiBlockAnalysis = json.decode(r.body));
    } catch (_) {}
  }

  Future<void> _loadBlock(String h) async {
    setState(() { loading = true; aiBlockAnalysis = null; });
    try {
      final r = await http.get(Uri.parse('http://node.local:4402/api/block/$h'));
      if (mounted) setState(() { blk = json.decode(r.body); txn = null; loading = false; _push('block'); });
      // Auto-fetch AI block analysis
      if (info?['ai']?['enabled'] == true && info?['ai']?['ollama_connected'] == true) {
        _loadBlockAi(h);
      }
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadAddr(String a) async {
    setState(() { loading = true; addr = null; blk = null; txn = null; });
    try {
      final r = await http.get(Uri.parse('http://node.local:4402/api/address/$a'));
      if (mounted) setState(() { addr = json.decode(r.body); loading = false; _push('addr'); });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  Future<void> _loadTx(String id) async {
    setState(() => loading = true);
    try {
      final r = await http.get(Uri.parse('http://node.local:4402/api/tx/$id'));
      if (mounted) setState(() { txn = json.decode(r.body); loading = false; _push('tx'); });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  void _search() {
    final q = sc.text.trim();
    if (q.isEmpty) { _load(); return; }
    if (RegExp(r'^\d+$').hasMatch(q)) {
      http.get(Uri.parse('http://node.local:4402/api/blockhash/$q')).then((r) {
        final d = json.decode(r.body);
        if (d['hash'] != null) _loadBlock(d['hash']);
      });
    } else if (q.startsWith('S') || q.startsWith('shrd1') || q.startsWith('s')) {
      _loadAddr(q);
    } else if (q.length == 64 && RegExp(r'^[a-f0-9]+$').hasMatch(q)) {
      // Try block first, fall back to txid
      http.get(Uri.parse('http://node.local:4402/api/block/$q')).then((r) {
        final d = json.decode(r.body);
        if (d['hash'] != null) { _loadBlock(q); } else { _loadTx(q); }
      }).catchError((_) => _loadTx(q));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: const BoxDecoration(color: C.bg, border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
          child: Row(children: [
            MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
              onTap: _load,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), gradient: const LinearGradient(colors: [C.purple, C.green])),
                  child: const Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)))),
                const SizedBox(width: 10),
                Text('ShardCoin ', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Explorer', style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: C.t3)),
              ]),
            )),
            const Spacer(),
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(100), border: Border.all(color: C.line, width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: C.green,
                  boxShadow: [BoxShadow(color: C.green.withValues(alpha: 0.5), blurRadius: 6)])),
                const SizedBox(width: 6),
                Text(info != null ? 'Height ${info!['blocks']}' : 'Connecting...', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t2)),
              ]),
            ),
          ]),
        ),

        // SEARCH BAR
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: C.bg2,
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(children: [
              Expanded(child: TextField(
                controller: sc, onSubmitted: (_) => _search(),
                style: GoogleFonts.jetBrainsMono(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by block height, block hash, txid, or wallet address (S.../shrd1...)',
                  hintStyle: GoogleFonts.inter(color: C.t3, fontSize: 13),
                  filled: true, fillColor: C.card,
                  prefixIcon: const Icon(Icons.search_rounded, color: C.t3, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.line, width: 0.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.purple)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), isDense: true,
                ),
              )),
              const SizedBox(width: 8),
              _btn('Search', onTap: _search),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: C.line, width: 0.5)),
                child: IconButton(icon: const Icon(Icons.refresh_rounded, color: C.t3, size: 18), onPressed: _load, splashRadius: 18, padding: const EdgeInsets.all(8), constraints: const BoxConstraints()),
              ),
            ]),
          )),
        ),

        // CONTENT
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: loading
            ? const Center(child: CircularProgressIndicator(color: C.purple, strokeWidth: 2))
            : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_rounded, color: C.t3, size: 48),
                  const SizedBox(height: 16),
                  Text(error!, style: GoogleFonts.inter(color: C.t3, fontSize: 14)),
                  const SizedBox(height: 12),
                  _btn('Retry', onTap: _load),
                ]))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: SingleChildScrollView(
                    child: addr != null ? _addrView() : txn != null ? _txView() : blk != null ? _blockView() : _homeView(),
                  ),
                ),
        ))),

        // FOOTER
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: const BoxDecoration(color: C.bg2, border: Border(top: BorderSide(color: C.line, width: 0.5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final e in {
              'GitHub': 'https://github.com/code2031/ShardCoin',
              'Releases': 'https://github.com/code2031/ShardCoin/releases',
              'ShardWallet': 'https://github.com/code2031/ShardWallet',
              'Chain Data': 'https://github.com/code2031/ShardChain-data',
            }.entries)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                  onTap: () => _openUrl(e.value),
                  child: Text(e.key, style: GoogleFonts.inter(fontSize: 12, color: C.t3)),
                ))),
          ]),
        ),
      ]),
    );
  }

  // ---- WIDGETS ----

  Widget _btn(String text, {VoidCallback? onTap}) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: [C.purple, C.green])),
      child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black)),
    )),
  );

  Widget _back(VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(alignment: Alignment.centerLeft, child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.arrow_back_rounded, size: 14, color: C.t3),
        const SizedBox(width: 4),
        Text('Back', style: GoogleFonts.inter(fontSize: 12, color: C.t3)),
      ])),
    )),
  );

  Widget _kv(String k, String v, {VoidCallback? tap, Color? vc}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
    child: Row(children: [
      SizedBox(width: 140, child: Text(k, style: GoogleFonts.inter(fontSize: 12, color: C.t3, fontWeight: FontWeight.w500))),
      Expanded(child: MouseRegion(
        cursor: tap != null ? SystemMouseCursors.click : SystemMouseCursors.text,
        child: GestureDetector(onTap: tap, child: SelectableText(v,
          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: vc ?? (tap != null ? C.purple : C.t1)))),
      )),
    ]),
  );

  Widget _section(String title, List<Widget> children, {Color accent = C.green}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line, width: 0.5)),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
        decoration: BoxDecoration(color: C.card2, border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
        child: Row(children: [
          Container(width: 3, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: accent)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
      ...children,
    ]),
  );

  // ---- VIEWS ----

  Widget _aiCard(String title, Map<String, dynamic>? data, {Color accent = C.purple}) {
    if (data == null || data['error'] != null) return const SizedBox.shrink();
    final analysis = data['analysis'] as String? ?? data['recommendation'] as String?;
    if (analysis == null || analysis.isEmpty) return const SizedBox.shrink();
    return _section(title, [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: SelectableText(analysis, style: GoogleFonts.inter(fontSize: 13, color: C.t2, height: 1.6)),
      ),
      if (data['model'] != null) Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Text('Model: ${data['model']}', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: C.t3)),
      ),
    ], accent: accent);
  }

  Widget _homeView() => Column(children: [
    // Network overview
    if (info != null) _section('Network Overview', [
      _kv('Height', '${info!['blocks'] ?? '-'}'),
      _kv('Difficulty', '${info!['difficulty'] ?? '-'}'),
      _kv('Chain', '${info!['chain'] ?? '-'}'),
      _kv('Best Block', '${info!['bestblockhash'] ?? '-'}'),
      if (info!['ai'] != null) ...[
        _kv('AI Proof-of-Work', info!['ai']['enabled'] == true ? 'Enabled' : 'Disabled', vc: info!['ai']['enabled'] == true ? C.green : C.t3),
        _kv('Ollama Status', info!['ai']['ollama_connected'] == true ? 'Connected' : 'Offline', vc: info!['ai']['ollama_connected'] == true ? C.green : C.pink),
        _kv('AI Model', '${info!['ai']['model'] ?? '-'}'),
      ],
    ]),

    // AI Insights (auto-loaded)
    if (aiLoading) Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: C.purple, strokeWidth: 2)),
        const SizedBox(width: 10),
        Text('AI analyzing network...', style: GoogleFonts.inter(fontSize: 12, color: C.t3)),
      ]),
    ),
    _aiCard('AI Network Analysis', aiNetwork, accent: C.purple),
    _aiCard('AI Mempool Analysis', aiMempool, accent: C.blue),
    if (aiFee != null && aiFee!['recommendation'] != null)
      _section('AI Fee Recommendation', [
        if (aiFee!['recommended_fee_rate'] != null) _kv('Rate', '${aiFee!['recommended_fee_rate']} sat/kB', vc: C.green),
        if (aiFee!['recommendation'] != null) Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SelectableText('${aiFee!['recommendation']}', style: GoogleFonts.inter(fontSize: 13, color: C.t2, height: 1.6)),
        ),
        if (aiFee!['model'] != null) Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text('Model: ${aiFee!['model']}', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: C.t3)),
        ),
      ], accent: C.green),

    // Blocks list
    _section('Recent Blocks', [
      // Header row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
        child: Row(children: [
          SizedBox(width: 60, child: Text('HEIGHT', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
          Expanded(child: Text('HASH', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
          SizedBox(width: 70, child: Text('TIME', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
          SizedBox(width: 50, child: Text('TXS', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
          const SizedBox(width: 36),
        ]),
      ),
      // Block rows
      for (final b in blocks) _blockRow(b),
    ], accent: C.blue),
  ]);

  Widget _blockRow(dynamic b) => InkWell(
    onTap: () => _loadBlock(b['hash']),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
      child: Row(children: [
        SizedBox(width: 60, child: Text('#${b['height']}', style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: C.green))),
        Expanded(child: Text('${b['hash']}'.substring(0, 24) + '...', overflow: TextOverflow.ellipsis, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
        SizedBox(width: 70, child: Text(
          DateTime.fromMillisecondsSinceEpoch(b['time'] * 1000).toLocal().toString().substring(11, 19),
          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
        SizedBox(width: 50, child: Text('${b['tx']}', textAlign: TextAlign.right, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t2))),
        SizedBox(width: 36, child: b['ai'] == true
          ? Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [C.purple, C.green]), borderRadius: BorderRadius.circular(8)),
              child: Text('AI', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black)))
          : const SizedBox()),
      ]),
    ),
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
  );

  Widget _addr(String? address, {double size = 11}) => MouseRegion(
    cursor: address != null && address != 'unknown' && !address.startsWith('Block') ? SystemMouseCursors.click : SystemMouseCursors.text,
    child: GestureDetector(
      onTap: address != null && address != 'unknown' && !address.startsWith('Block') ? () => _loadAddr(address) : null,
      child: Text(address ?? 'unknown', style: GoogleFonts.jetBrainsMono(fontSize: size,
        color: address != null && address != 'unknown' && !address.startsWith('Block') ? C.purple : C.t2), overflow: TextOverflow.ellipsis),
    ),
  );

  Widget _blockView() {
    final b = blk!;
    final txList = b['tx'] as List? ?? [];
    return Column(children: [
      _back(() { _pop(); setState(() { blk = null; txn = null; }); }),

      // Block summary
      _section('Block #${b['height'] ?? '?'}', [
        _kv('Hash', '${b['hash']}'),
        _kv('Confirmations', '${b['confirmations'] ?? '-'}', vc: C.green),
        _kv('Timestamp', DateTime.fromMillisecondsSinceEpoch(b['time'] * 1000).toLocal().toString()),
        _kv('Transactions', '${txList.length}'),
        if (b['block_reward'] != null) _kv('Block Reward', '${b['block_reward']} SHRD', vc: C.green),
        if (b['total_fees'] != null) _kv('Total Fees', '${b['total_fees']} SHRD'),
        if (b['total_output'] != null) _kv('Total Output', '${b['total_output']} SHRD'),
        _kv('Difficulty', '${b['difficulty']}'),
        _kv('Size', '${b['size']} bytes'),
        _kv('Weight', '${b['weight']} WU'),
        _kv('Nonce', '${b['nonce']}'),
        _kv('Bits', '${b['bits'] ?? '-'}'),
        _kv('Merkle Root', '${b['merkleroot'] ?? '-'}'),
        _kv('Version', '0x${(b['version'] as int?)?.toRadixString(16) ?? '-'}'),
        _kv('Chain Work', '${b['chainwork'] ?? '-'}'),
        _kv('Previous Block', b['previousblockhash'] ?? 'Genesis',
          tap: b['previousblockhash'] != null ? () => _loadBlock(b['previousblockhash']) : null),
        if (b['nextblockhash'] != null)
          _kv('Next Block', '${b['nextblockhash']}', tap: () => _loadBlock(b['nextblockhash'])),
      ]),

      // AI Proof
      if (b['ai_proof'] != null) _section('AI Proof', [
        _kv('Status', 'Verified', vc: C.green),
        _kv('Response Hash', '${b['ai_proof']['response_hash']}'),
        _kv('Model Tag', '${b['ai_proof']['model_tag']}'),
      ], accent: C.purple),

      // AI Block Analysis
      if (aiBlockAnalysis == null && info?['ai']?['ollama_connected'] == true)
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: C.purple, strokeWidth: 2)),
          const SizedBox(width: 10),
          Text('AI analyzing block...', style: GoogleFonts.inter(fontSize: 12, color: C.t3)),
        ])),
      _aiCard('AI Block Analysis', aiBlockAnalysis, accent: C.purple),

      // Full transaction details
      for (var i = 0; i < txList.length; i++) _txCard(txList[i], i),
    ]);
  }

  Widget _txCard(dynamic tx, int index) {
    final senders = tx['senders'] as List? ?? [];
    final receivers = tx['receivers'] as List? ?? [];
    final isCoinbase = tx['is_coinbase'] == true;
    final txid = tx['txid'] ?? '';
    final fee = tx['fee'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line, width: 0.5)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tx header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(color: C.card2, border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
          child: Row(children: [
            Container(width: 3, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: isCoinbase ? C.green : C.blue)),
            const SizedBox(width: 10),
            Text('TX #$index', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (isCoinbase) _tag('COINBASE', C.green),
            if (!isCoinbase && fee > 0) ...[const SizedBox(width: 6), _tag('FEE: $fee SHRD', C.blue)],
            const Spacer(),
            MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
              onTap: () => _loadTx(txid),
              child: Text('View Full', style: GoogleFonts.inter(fontSize: 11, color: C.purple, fontWeight: FontWeight.w500)),
            )),
          ]),
        ),
        // TXID
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
          child: Row(children: [
            Text('TXID  ', style: GoogleFonts.inter(fontSize: 10, color: C.t3, fontWeight: FontWeight.w600)),
            Expanded(child: SelectableText(txid, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t2))),
          ]),
        ),
        // Senders -> Receivers layout
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // FROM column
          Expanded(child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: C.line, width: 0.5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.arrow_upward_rounded, size: 12, color: C.pink),
                const SizedBox(width: 4),
                Text('FROM', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              for (final s in senders) Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _addr(s['address']),
                  if (!isCoinbase && s['amount'] != null && s['amount'] != 0)
                    Text('${s['amount']} SHRD', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: C.pink)),
                ]),
              ),
            ]),
          )),
          // Arrow
          Container(
            width: 32,
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_forward_rounded, size: 16, color: C.t3),
          ),
          // TO column
          Expanded(child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.arrow_downward_rounded, size: 12, color: C.green),
                const SizedBox(width: 4),
                Text('TO', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              for (final r in receivers) Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: r['op_return'] == true
                      ? Row(children: [
                          _tag(r['is_ai_proof'] == true ? 'AI PROOF' : 'OP_RETURN', r['is_ai_proof'] == true ? C.purple : C.t3),
                          if (r['data_hex'] != null) ...[
                            const SizedBox(width: 4),
                            Expanded(child: Text('${r['data_hex']}'.substring(0, (r['data_hex'] as String).length.clamp(0, 24)) + '...',
                              style: GoogleFonts.jetBrainsMono(fontSize: 9, color: C.t3), overflow: TextOverflow.ellipsis)),
                          ],
                        ])
                      : _addr(r['address'])),
                  ]),
                  if (r['amount'] != null && r['amount'] != 0)
                    Text('${r['amount']} SHRD', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w600, color: C.green)),
                  if (r['type'] != null && r['type'] != 'nulldata')
                    Text(r['type'], style: GoogleFonts.inter(fontSize: 9, color: C.t3)),
                ]),
              ),
            ]),
          )),
        ])),
      ]),
    );
  }

  Widget _txView() {
    final t = txn!;
    final vin = t['vin'] as List? ?? [];
    final vout = t['vout'] as List? ?? [];
    return Column(children: [
      _back(() { _pop(); setState(() => txn = null); }),

      _section('Transaction', [
        _kv('TXID', '${t['txid']}'),
        if (t['blockhash'] != null) _kv('Block', '${t['blockhash']}', tap: () => _loadBlock(t['blockhash'])),
        if (t['confirmations'] != null) _kv('Confirmations', '${t['confirmations']}', vc: C.green),
        if (t['blocktime'] != null) _kv('Block Time', DateTime.fromMillisecondsSinceEpoch(t['blocktime'] * 1000).toLocal().toString()),
        _kv('Size', '${t['size']} bytes'),
        _kv('Virtual Size', '${t['vsize'] ?? t['size']} vbytes'),
        _kv('Weight', '${t['weight'] ?? '-'} WU'),
        _kv('Version', '${t['version']}'),
        _kv('Locktime', '${t['locktime']}'),
        _kv('Inputs', '${vin.length}'),
        _kv('Outputs', '${vout.length}'),
        if (t['hex'] != null) _kv('Raw Hex Size', '${(t['hex'] as String).length ~/ 2} bytes'),
      ]),

      // Inputs
      _section('Inputs (${vin.length})', [
        for (var i = 0; i < vin.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
            child: Row(children: [
              SizedBox(width: 28, child: Text('$i', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
              Expanded(child: vin[i]['coinbase'] != null
                ? Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: C.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text('coinbase', style: GoogleFonts.inter(fontSize: 10, color: C.green, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${vin[i]['coinbase']}'.substring(0, (vin[i]['coinbase'] as String).length.clamp(0, 40)) + '...', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${vin[i]['txid']}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.purple)),
                    Text('Output index: ${vin[i]['vout']}', style: GoogleFonts.inter(fontSize: 11, color: C.t3)),
                  ]),
              ),
            ]),
          ),
      ], accent: C.purple),

      // Outputs
      _section('Outputs (${vout.length})', [
        for (var i = 0; i < vout.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
            child: Row(children: [
              SizedBox(width: 28, child: Text('$i', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MouseRegion(
                  cursor: vout[i]['scriptPubKey']?['address'] != null ? SystemMouseCursors.click : SystemMouseCursors.text,
                  child: GestureDetector(
                    onTap: vout[i]['scriptPubKey']?['address'] != null ? () => _loadAddr(vout[i]['scriptPubKey']['address']) : null,
                    child: Text(vout[i]['scriptPubKey']?['address'] ?? vout[i]['scriptPubKey']?['type'] ?? 'unknown',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: vout[i]['scriptPubKey']?['address'] != null ? C.purple : C.t1)),
                  ),
                ),
                if (vout[i]['scriptPubKey']?['type'] != null)
                  Text(vout[i]['scriptPubKey']['type'], style: GoogleFonts.inter(fontSize: 10, color: C.t3)),
              ])),
              Text('${vout[i]['value']} SHRD', style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: C.green)),
            ]),
          ),
      ], accent: C.green),
    ]);
  }

  Widget _addrView() {
    final a = addr!;
    final utxos = a['utxos'] as List? ?? [];
    final txs = a['transactions'] as List? ?? [];
    return Column(children: [
      _back(() { _pop(); setState(() => addr = null); }),

      _section('Address', [
        _kv('Address', '${a['address']}'),
        _kv('Balance', '${a['balance']} SHRD', vc: C.green),
        _kv('UTXOs', '${a['utxo_count']}'),
        _kv('Transactions', '${txs.length}'),
      ]),

      // UTXOs
      if (utxos.isNotEmpty) _section('Unspent Outputs (${utxos.length})', [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
          child: Row(children: [
            Expanded(flex: 3, child: Text('TXID', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
            SizedBox(width: 50, child: Text('VOUT', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
            SizedBox(width: 60, child: Text('HEIGHT', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
            SizedBox(width: 100, child: Text('AMOUNT', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1, fontWeight: FontWeight.w700))),
          ]),
        ),
        for (final u in utxos)
          InkWell(
            onTap: () => _loadTx(u['txid']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
              child: Row(children: [
                Expanded(flex: 3, child: Text('${u['txid']}'.substring(0, 20) + '...', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.purple), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 50, child: Text('${u['vout']}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
                SizedBox(width: 60, child: Text('${u['height']}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.t3))),
                SizedBox(width: 100, child: Text('${u['amount']} SHRD', textAlign: TextAlign.right, style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: C.green))),
              ]),
            ),
          ),
      ], accent: C.blue),

      // Transaction history
      if (txs.isNotEmpty) _section('Transaction History (${txs.length})', [
        for (final tx in txs)
          InkWell(
            onTap: () => _loadTx(tx['txid']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
              child: Row(children: [
                Expanded(child: Text('${tx['txid']}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: C.purple), overflow: TextOverflow.ellipsis)),
                if (tx['blocktime'] != null) Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(DateTime.fromMillisecondsSinceEpoch(tx['blocktime'] * 1000).toLocal().toString().substring(0, 16),
                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: C.t3)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('${tx['amount']} SHRD', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: C.green)),
                ),
              ]),
            ),
          ),
      ], accent: C.green),
    ]);
  }
}
