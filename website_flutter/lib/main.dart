import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'url_helper.dart' if (dart.library.js_interop) 'url_helper_web.dart' as platform;

void _openUrl(String url) => platform.openUrl(url);

void main() => runApp(const App());

// ===== COLORS =====
class C {
  static const bg      = Color(0xFF050508);
  static const bg2     = Color(0xFF0B0B10);
  static const card    = Color(0xFF101018);
  static const card2   = Color(0xFF161622);
  static const line    = Color(0xFF1E1E30);
  static const line2   = Color(0xFF2A2A40);
  static const t1      = Color(0xFFF4F4F8);
  static const t2      = Color(0xFFA8A8BC);
  static const t3      = Color(0xFF68687E);
  static const green   = Color(0xFF14F195);
  static const purple  = Color(0xFF9945FF);
  static const blue    = Color(0xFF4DA2FF);
  static const pink    = Color(0xFFEB459E);
}

// ===== APP =====
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShardCoin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: C.bg,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => Shell(route: settings.name ?? '/'), settings: settings);
      },
    );
  }
}

// ===== SHELL =====
class Shell extends StatefulWidget {
  final String route;
  const Shell({super.key, this.route = '/'});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  final tabs = ['Home', 'Technology', 'Download', 'Network', 'Explorer'];
  final _routes = ['/', '/technology', '/download', '/network', '/explorer'];

  @override
  void initState() {
    super.initState();
    final i = _routes.indexOf(widget.route);
    if (i >= 0) tab = i;
  }

  void _switchTab(int i) {
    _switchTab(i);
    Navigator.of(context).pushReplacementNamed(_routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 860;
    return SelectionArea(child: Scaffold(
      body: Column(children: [
        // NAV
        Container(
          height: 56,
          decoration: const BoxDecoration(color: C.bg, border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            // Logo
            MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
              onTap: () => _switchTab(0),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), gradient: const LinearGradient(colors: [C.purple, C.green])),
                  child: const Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)))),
                const SizedBox(width: 10),
                Text('ShardCoin', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
            )),
            const SizedBox(width: 36),
            // Tabs
            if (wide) ...List.generate(tabs.length, (i) => _tab(i)),
            const Spacer(),
            // GitHub button
            MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
              onTap: () => _openUrl('https://github.com/code2031/ShardCoin'),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: [C.purple, C.green])),
              child: Text('GitHub', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black)),
            ))),
          ]),
        ),
        // PAGE
        Expanded(child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(tab), child: [
            HomePage(onNav: (i) => _switchTab(i)),
            const TechPage(), const DlPage(), const NetPage(), const ExpPage(),
          ][tab]),
        )),
      ]),
      // Mobile nav
      bottomNavigationBar: wide ? null : BottomNavigationBar(
        currentIndex: tab, onTap: (i) => _switchTab(i),
        type: BottomNavigationBarType.fixed, backgroundColor: C.bg2,
        selectedItemColor: C.green, unselectedItemColor: C.t3,
        selectedFontSize: 10, unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 20), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.memory_rounded, size: 20), label: 'Tech'),
          BottomNavigationBarItem(icon: Icon(Icons.download_rounded, size: 20), label: 'Download'),
          BottomNavigationBarItem(icon: Icon(Icons.hub_rounded, size: 20), label: 'Network'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded, size: 20), label: 'Explorer'),
        ],
      ),
    ));
  }

  Widget _tab(int i) {
    final on = i == tab;
    return Padding(padding: const EdgeInsets.only(right: 2), child: TextButton(
      onPressed: () => _switchTab(i),
      style: TextButton.styleFrom(
        backgroundColor: on ? C.card2 : Colors.transparent,
        foregroundColor: on ? C.t1 : C.t3,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        minimumSize: Size.zero,
      ),
      child: Text(tabs[i], style: GoogleFonts.inter(fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w500)),
    ));
  }
}

// ===== SHARED =====
class Sec extends StatelessWidget {
  final String title, sub;
  const Sec(this.title, this.sub, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 48),
    child: Column(children: [
      Text(title, style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.8), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540),
        child: Text(sub, style: GoogleFonts.inter(fontSize: 15, color: C.t2, height: 1.65), textAlign: TextAlign.center)),
    ]),
  );
}

class Wrap2 extends StatelessWidget {
  final int minW;
  final double gap;
  final List<Widget> children;
  const Wrap2({super.key, this.minW = 320, this.gap = 16, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final cols = (c.maxWidth / minW).floor().clamp(1, children.length);
    final w = (c.maxWidth - gap * (cols - 1)) / cols;
    return Wrap(spacing: gap, runSpacing: gap, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
  });
}

class Kard extends StatefulWidget {
  final Widget child;
  const Kard({super.key, required this.child});
  @override
  State<Kard> createState() => _KardState();
}
class _KardState extends State<Kard> {
  bool h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => h = true), onExit: (_) => setState(() => h = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: h ? C.card2 : C.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: h ? C.line2 : C.line, width: 0.5),
      ),
      child: widget.child,
    ),
  );
}

Widget _page(List<Widget> children) => SingleChildScrollView(
  child: Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1080),
    child: Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
  )),
);

class Foot extends StatelessWidget {
  const Foot({super.key});
  static const _links = {
    'GitHub': 'https://github.com/code2031/ShardCoin',
    'Releases': 'https://github.com/code2031/ShardCoin/releases',
    'ShardWallet': 'https://github.com/code2031/ShardWallet',
    'Chain Data': 'https://github.com/code2031/ShardChain-data',
  };
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line, width: 0.5))),
    child: Column(children: [
      Wrap(spacing: 28, runSpacing: 8, alignment: WrapAlignment.center, children: [
        for (final e in _links.entries)
          MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
            onTap: () => _openUrl(e.value),
            child: Text(e.key, style: GoogleFonts.inter(fontSize: 13, color: C.t3)),
          )),
      ]),
      const SizedBox(height: 16),
      Text('ShardCoin is open source under the MIT license.', style: GoogleFonts.inter(fontSize: 11, color: C.t3)),
    ]),
  );
}

// ===== HOME =====
class HomePage extends StatelessWidget {
  final void Function(int)? onNav;
  const HomePage({super.key, this.onNav});
  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.of(context).size.width > 800;
    return _page([
      // Hero
      SizedBox(height: big ? 100 : 60),
      Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(100), border: Border.all(color: C.line2, width: 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: C.green, boxShadow: [BoxShadow(color: C.green.withValues(alpha: 0.5), blurRadius: 6)])),
          const SizedBox(width: 8),
          Text('AI-Native Blockchain', style: GoogleFonts.inter(fontSize: 12, color: C.t2, fontWeight: FontWeight.w500)),
        ]),
      )),
      const SizedBox(height: 32),
      Center(child: Text('Powerful for miners.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: big ? 52 : 34, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1.1))),
      Center(child: ShaderMask(
        shaderCallback: (b) => const LinearGradient(colors: [C.purple, C.blue, C.green]).createShader(b),
        child: Text('Intelligent by design.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: big ? 52 : 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -2)),
      )),
      const SizedBox(height: 20),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
        child: Text('The first cryptocurrency where every block is proof of artificial intelligence. Scrypt mining meets local AI inference via Ollama.',
          textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: C.t2, height: 1.7)))),
      const SizedBox(height: 36),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
          onTap: () => onNav?.call(2),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [C.purple, C.green])),
            child: Text('Get Started', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black))))),
        const SizedBox(width: 12),
        MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
          onTap: () => _openUrl('https://github.com/code2031/ShardCoin/blob/master/WHITEPAPER.md'),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: C.card2, border: Border.all(color: C.line2)),
            child: Text('Read Whitepaper', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))))),
      ]),
      const SizedBox(height: 72),

      // Stats
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line, width: 0.5)),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 600 ? 4 : 2;
          final stats = [('5 SHRD', 'Block Reward', C.green), ('~8.4M', 'Max Supply', C.purple), ('2.5 min', 'Block Time', C.blue), ('Scrypt+AI', 'Algorithm', C.green)];
          return Wrap(children: [
            for (final s in stats)
              SizedBox(width: c.maxWidth / cols, child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(color: C.card, border: Border.all(color: C.line, width: 0.25)),
                child: Column(children: [
                  Text(s.$1, style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w700, color: s.$3)),
                  const SizedBox(height: 4),
                  Text(s.$2.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                ]),
              )),
          ]);
        }),
      ),
      const SizedBox(height: 80),

      // Features
      const Sec('Built for the AI era', 'ShardCoin combines battle-tested blockchain security with AI inference, creating a network that rewards running AI infrastructure.'),
      Wrap2(children: [
        for (final f in [
          ('\u{1F9E0}', 'AI Proof-of-Work', 'Every block includes a cryptographic proof of AI inference via local Ollama models.', C.purple),
          ('\u{26A1}', 'AI Fee Estimation', 'AI analyzes mempool conditions and recommends optimal fees based on demand.', C.green),
          ('\u{1F4CA}', 'AI Network Analysis', 'Built-in AI commands analyze blocks, mempool, and network health.', C.blue),
          ('\u{1F510}', 'MWEB Privacy', 'Confidential transactions with hidden amounts via Pedersen commitments.', C.pink),
          ('\u{2B50}', 'Taproot from Genesis', 'Schnorr signatures, MAST, key-path spending active from block 0.', C.green),
          ('\u{1F4C8}', 'Smooth Decay', '10% reward reduction every 100k blocks instead of abrupt halvings.', C.blue),
        ])
          Kard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: f.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(f.$1, style: const TextStyle(fontSize: 18)))),
            const SizedBox(height: 16),
            Text(f.$2, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(f.$3, style: GoogleFonts.inter(fontSize: 13, color: C.t2, height: 1.55)),
          ])),
      ]),
      const SizedBox(height: 80),
      const Foot(),
    ]);
  }
}

// ===== TECHNOLOGY =====
class TechPage extends StatelessWidget {
  const TechPage({super.key});
  @override
  Widget build(BuildContext context) => _page([
    const SizedBox(height: 72),
    const Sec('How AI Mining Works', 'Four steps transform a standard block into an AI-verified unit of work.'),
    Wrap2(minW: 220, children: [
      for (final s in [
        ('01', 'Challenge', 'Deterministic prompt from previous block hash and height.', C.purple),
        ('02', 'Inference', 'Local Ollama processes the challenge through a language model.', C.blue),
        ('03', 'Commit', '41-byte AIPR proof embedded in coinbase OP_RETURN.', C.green),
        ('04', 'Mine', 'Scrypt PoW completes the block with AI proof in Merkle root.', C.pink),
      ])
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(shaderCallback: (b) => LinearGradient(colors: [s.$4, s.$4.withValues(alpha: 0.3)]).createShader(b),
              child: Text(s.$1, style: GoogleFonts.jetBrainsMono(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white))),
            const SizedBox(height: 12),
            Text(s.$2, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(s.$3, style: GoogleFonts.inter(fontSize: 13, color: C.t2, height: 1.5)),
          ]),
        ),
    ]),
    const SizedBox(height: 72),
    const Sec('AI RPC Commands', 'Seven AI-powered commands built directly into the node.'),
    _table([
      ('getaiinfo', 'AI subsystem status, Ollama connection, models'),
      ('getaichallenge', 'Current AI challenge for the next block'),
      ('getaiproof <hash>', 'Extract AI proof from a block'),
      ('estimateaifee [urgency]', 'AI fee estimation (low / normal / high)'),
      ('analyzaiblock <hash>', 'AI analysis of block content'),
      ('analyzaimempool', 'AI mempool congestion analysis'),
      ('analyzainetwork', 'AI network health report'),
    ]),
    const SizedBox(height: 80),
    const Foot(),
  ]);
}

Widget _table(List<(String, String)> rows) => Container(
  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line, width: 0.5)),
  clipBehavior: Clip.antiAlias,
  child: Column(children: [
    Container(color: C.card2, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        SizedBox(width: 240, child: Text('COMMAND', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
        Expanded(child: Text('DESCRIPTION', style: GoogleFonts.inter(fontSize: 10, color: C.t3, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
      ])),
    for (final r in rows)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line, width: 0.5))),
        child: Row(children: [
          SizedBox(width: 240, child: Text(r.$1, style: GoogleFonts.jetBrainsMono(fontSize: 13, color: C.green))),
          Expanded(child: Text(r.$2, style: GoogleFonts.inter(fontSize: 13, color: C.t2))),
        ]),
      ),
  ]),
);

// ===== DOWNLOAD =====
class DlPage extends StatelessWidget {
  const DlPage({super.key});
  @override
  Widget build(BuildContext context) => _page([
    const SizedBox(height: 72),
    const Sec('Download ShardCoin', 'Get the node software, wallet, or build from source.'),
    Wrap2(children: [
      for (final d in [
        ('ShardCoin Core', 'Full node, CLI, tx tool, wallet utility.\nLinux aarch64. AI PoW included.', 'Download v0.1.0', true, C.purple),
        ('ShardWallet', 'Non-custodial PWA wallet.\nBIP39, client-side signing, any browser.', 'View on GitHub', false, C.green),
        ('Source Code', 'Build from source. ShardCoin fork\nwith AI PoW and all features from genesis.', 'View on GitHub', false, C.blue),
      ])
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line, width: 0.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36, height: 3, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: LinearGradient(colors: [d.$5, d.$5.withValues(alpha: 0.2)]))),
            const SizedBox(height: 20),
            Text(d.$1, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(d.$2, style: GoogleFonts.inter(fontSize: 13, color: C.t2, height: 1.55)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: d.$4 ? const LinearGradient(colors: [C.purple, C.green]) : null,
                color: d.$4 ? null : C.card2, border: d.$4 ? null : Border.all(color: C.line2)),
              child: Text(d.$3, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: d.$4 ? Colors.black : C.t1)),
            ),
          ]),
        ),
    ]),
    const SizedBox(height: 28),
    Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line, width: 0.5)),
      child: SelectableText(
        '# Quick start\n\$ tar xzf shardcoin-core-linux-aarch64.tar.gz && cd shardcoin-core\n\n'
        '# Start the node\n\$ ./shardcoind -daemon\n\$ ./shardcoin-cli getblockchaininfo\n\n'
        '# Mine with AI (requires Ollama)\n\$ ollama serve &\n\$ ./shardcoin-cli createwallet "main"\n\$ ./shardcoin-cli -generate 1',
        style: GoogleFonts.jetBrainsMono(fontSize: 12.5, color: C.green, height: 1.7)),
    ),
    const SizedBox(height: 80),
    const Foot(),
  ]);
}

// ===== NETWORK =====
class NetPage extends StatelessWidget {
  const NetPage({super.key});
  @override
  Widget build(BuildContext context) => _page([
    const SizedBox(height: 72),
    const Sec('Network Parameters', 'Everything you need to integrate with ShardCoin.'),
    _table([
      ('Ticker', 'SHRD'), ('Algorithm', 'Scrypt + AI Proof-of-Work'),
      ('Block Time', '2.5 minutes'), ('Max Supply', '~8,400,000 SHRD'),
      ('Block Reward', '5 SHRD (10% decay / 100k blocks)'),
      ('P2P Port', '7333'), ('RPC Port', '7332'),
      ('Address Prefix', 'S (bech32: shrd1...)'), ('BIP44 Coin Type', '1000'),
      ('P2PKH', '63'), ('P2SH', '5'), ('Bech32 HRP', 'shrd'),
      ('WIF', '191'), ('Magic', '0xd3a2c4e7'),
      ('BIP32 Public', '0x0488B21E'), ('BIP32 Private', '0x0488ADE4'),
    ]),
    const SizedBox(height: 80),
    const Foot(),
  ]);
}

// ===== EXPLORER =====
class ExpPage extends StatelessWidget {
  const ExpPage({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.explore_rounded, size: 64, color: C.t3),
      const SizedBox(height: 24),
      Text('ShardCoin Explorer', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Browse blocks, transactions, and AI proofs', style: GoogleFonts.inter(fontSize: 15, color: C.t2)),
      const SizedBox(height: 32),
      MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
        onTap: () => _launchExplorer(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [C.purple, C.green])),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Open Explorer', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black)),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.black),
          ]),
        ),
      )),
      const SizedBox(height: 12),
      Text('node.local:4402', style: GoogleFonts.jetBrainsMono(fontSize: 13, color: C.t3)),
    ]),
  );

  static void _launchExplorer() => _openUrl('http://node.local:4402');
}
