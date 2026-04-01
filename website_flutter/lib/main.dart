import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() => runApp(const ShardCoinApp());

// ============================================================
// THEME
// ============================================================
class S {
  static const bg = Color(0xFF050507);
  static const bg2 = Color(0xFF0A0A0E);
  static const surface = Color(0xFF0E0E14);
  static const surface2 = Color(0xFF141420);
  static const surface3 = Color(0xFF1A1A28);
  static const border = Color(0xFF1E1E30);
  static const border2 = Color(0xFF2C2C42);
  static const text = Color(0xFFF8F8FC);
  static const text2 = Color(0xFFB0B0C0);
  static const text3 = Color(0xFF6E6E84);
  static const green = Color(0xFF14F195);
  static const purple = Color(0xFF9945FF);
  static const blue = Color(0xFF4DA2FF);
  static const pink = Color(0xFFEB459E);
  static const grad = [purple, blue, green];
  static const grad2 = [purple, green];
  static const gradPink = [pink, purple, blue];
}

// ============================================================
// APP
// ============================================================
class ShardCoinApp extends StatelessWidget {
  const ShardCoinApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShardCoin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: S.bg,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
      ),
      home: const Shell(),
    );
  }
}

// ============================================================
// SHELL (Nav + Pages)
// ============================================================
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with TickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _fadeCtrl;
  late Animation<double> _fade;

  final _labels = ['Home', 'Technology', 'Download', 'Network', 'Explorer'];
  final _icons = [Icons.home_rounded, Icons.memory_rounded, Icons.download_rounded, Icons.hub_rounded, Icons.explore_rounded];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    _fadeCtrl.reverse().then((_) {
      setState(() => _tab = i);
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      body: Column(
        children: [
          // ---- NAV ----
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: S.bg.withValues(alpha: 0.85),
              border: const Border(bottom: BorderSide(color: S.border, width: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _logo(),
                  if (wide) ...[
                    const SizedBox(width: 40),
                    for (var i = 0; i < _labels.length; i++) _navBtn(i),
                  ],
                  const Spacer(),
                  _gradBtn('GitHub', small: true),
                ],
              ),
            ),
          ),
          // ---- CONTENT ----
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: [
                const HomePage(),
                const TechPage(),
                const DownloadPage(),
                const NetworkPage(),
                const ExplorerPage(),
              ][_tab],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide ? null : Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: S.border, width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: _switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: S.bg2,
          selectedItemColor: S.green,
          unselectedItemColor: S.text3,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [for (var i = 0; i < _labels.length; i++) BottomNavigationBarItem(icon: Icon(_icons[i], size: 20), label: _labels[i])],
        ),
      ),
    );
  }

  Widget _logo() => GestureDetector(
    onTap: () => _switchTab(0),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: const LinearGradient(colors: S.grad2, begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: const Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black, height: 1))),
        ),
        const SizedBox(width: 10),
        const Text('ShardCoin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3)),
      ]),
    ),
  );

  Widget _navBtn(int i) {
    final active = i == _tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => _switchTab(i),
        style: TextButton.styleFrom(
          backgroundColor: active ? S.surface2 : Colors.transparent,
          foregroundColor: active ? S.text : S.text3,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
        ),
        child: Text(_labels[i], style: TextStyle(fontSize: 13.5, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================
Widget _gradBtn(String text, {bool small = false, VoidCallback? onTap}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 18 : 28, vertical: small ? 8 : 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(small ? 8 : 12),
          gradient: const LinearGradient(colors: S.grad2, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: S.purple.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: small ? 13 : 15, color: Colors.black)),
      ),
    ),
  );
}

Widget _outlineBtn(String text, {VoidCallback? onTap}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: S.surface2,
          border: Border.all(color: S.border2),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    ),
  );
}

class GradText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final List<Color> colors;
  const GradText(this.text, {super.key, this.size = 44, this.weight = FontWeight.w800, this.colors = S.grad});
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => LinearGradient(colors: colors).createShader(b),
      child: Text(text, style: TextStyle(fontSize: size, fontWeight: weight, color: Colors.white, height: 1.15, letterSpacing: -1)),
    );
  }
}

class Glow extends StatelessWidget {
  final Color color;
  final double size;
  final Alignment align;
  const Glow({super.key, this.color = S.purple, this.size = 600, this.align = Alignment.topCenter});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: align,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: 0.12), Colors.transparent]),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title, sub;
  final bool center;
  const SectionHeader(this.title, this.sub, {super.key, this.center = true});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.2)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(sub, style: const TextStyle(fontSize: 16, color: S.text2, height: 1.65), textAlign: center ? TextAlign.center : TextAlign.left),
        ),
        const SizedBox(height: 56),
      ],
    );
  }
}

class Card2 extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  const Card2({super.key, required this.child, this.padding = const EdgeInsets.all(28)});
  @override
  State<Card2> createState() => _Card2State();
}
class _Card2State extends State<Card2> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _hovered ? S.surface2 : S.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? S.border2 : S.border, width: 0.5),
          boxShadow: _hovered ? [BoxShadow(color: S.purple.withValues(alpha: 0.06), blurRadius: 30)] : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: const BoxDecoration(color: S.bg2, border: Border(top: BorderSide(color: S.border, width: 0.5))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(colors: S.grad2)),
                child: const Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black))),
              ),
              const SizedBox(width: 8),
              const Text('ShardCoin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 32,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final l in ['GitHub', 'Releases', 'ShardWallet', 'Chain Data', 'Whitepaper'])
                Text(l, style: const TextStyle(fontSize: 13, color: S.text3)),
            ],
          ),
          const SizedBox(height: 20),
          Container(width: 48, height: 1, color: S.border),
          const SizedBox(height: 20),
          const Text('Open source under the MIT license', style: TextStyle(fontSize: 12, color: S.text3)),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Column(
        children: [
          // HERO
          Stack(
            children: [
              const Glow(color: S.purple, size: 700, align: Alignment(0, -0.8)),
              Glow(color: S.blue, size: 400, align: const Alignment(0.6, -0.3)),
              Padding(
                padding: EdgeInsets.fromLTRB(24, w > 800 ? 100 : 60, 24, 80),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(color: S.surface2, borderRadius: BorderRadius.circular(100), border: Border.all(color: S.border2, width: 0.5)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: S.green, boxShadow: [BoxShadow(color: S.green.withValues(alpha: 0.5), blurRadius: 8)])),
                            const SizedBox(width: 8),
                            const Text('AI-Native Blockchain', style: TextStyle(fontSize: 12.5, color: S.text2, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        const SizedBox(height: 36),
                        Text('Powerful for miners.', style: TextStyle(fontSize: w > 800 ? 56 : 36, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1.08)),
                        GradText('Intelligent by design.', size: w > 800 ? 56 : 36),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: const Text(
                            'The first cryptocurrency where every block is proof of artificial intelligence. Scrypt mining meets local AI inference via Ollama.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17, color: S.text2, height: 1.7),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [_gradBtn('Get Started'), _outlineBtn('Read Whitepaper')],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // STATS
          Container(
            decoration: const BoxDecoration(
              color: S.bg2,
              border: Border(top: BorderSide(color: S.border, width: 0.5), bottom: BorderSide(color: S.border, width: 0.5)),
            ),
            child: LayoutBuilder(builder: (ctx, c) {
              final items = [
                ('5 SHRD', 'Block Reward', S.green),
                ('~8.4M', 'Max Supply', S.purple),
                ('2.5 min', 'Block Time', S.blue),
                ('Scrypt+AI', 'Algorithm', S.green),
              ];
              return Wrap(
                children: [
                  for (final s in items)
                    SizedBox(
                      width: c.maxWidth > 700 ? c.maxWidth / 4 : c.maxWidth / 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(border: Border.all(color: S.border, width: 0.25)),
                        child: Column(children: [
                          Text(s.$1, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: s.$3, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text(s.$2.toUpperCase(), style: const TextStyle(fontSize: 10.5, color: S.text3, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ],
              );
            }),
          ),

          // FEATURES
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    const SectionHeader('Built for the AI era', 'ShardCoin combines battle-tested blockchain security with AI inference, creating a network that rewards running AI infrastructure.'),
                    LayoutBuilder(builder: (ctx, c) {
                      final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 500 ? 2 : 1;
                      final cards = [
                        ('\u{1F9E0}', 'AI Proof-of-Work', 'Every block includes a cryptographic proof of AI inference. Miners query local Ollama models and commit the response hash to the chain.', S.purple),
                        ('\u{26A1}', 'AI Fee Estimation', 'The AI analyzes mempool conditions in real-time and recommends optimal fees based on current demand and user urgency.', S.green),
                        ('\u{1F4CA}', 'AI Network Analysis', 'Built-in AI commands analyze blocks, mempool state, and overall network health with insights no traditional node offers.', S.blue),
                        ('\u{1F510}', 'MWEB Privacy', 'Optional Mimblewimble Extension Blocks provide confidential transactions with hidden amounts via Pedersen commitments.', S.pink),
                        ('\u{2B50}', 'Taproot from Genesis', 'Schnorr signatures, MAST, and key-path spending active from block 0. No activation delays, no technical debt.', S.green),
                        ('\u{1F4C8}', 'Smooth Decay', 'Block rewards decrease 10% every 100k blocks instead of abrupt halvings. Predictable supply, no mining revenue shocks.', S.blue),
                      ];
                      final gap = 16.0;
                      final cardW = (c.maxWidth - gap * (cols - 1)) / cols;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final f in cards)
                            SizedBox(
                              width: cardW,
                              child: Card2(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(color: f.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                      child: Center(child: Text(f.$1, style: const TextStyle(fontSize: 20))),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(f.$2, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Text(f.$3, style: const TextStyle(fontSize: 13.5, color: S.text2, height: 1.6)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}

// ============================================================
// TECHNOLOGY
// ============================================================
class TechPage extends StatelessWidget {
  const TechPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 80),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: SectionHeader('How AI Mining Works', 'Four steps transform a standard block into an AI-verified unit of work.'),
          ),
          // Steps
          LayoutBuilder(builder: (ctx, c) {
            final steps = [
              ('01', 'Challenge', 'A deterministic prompt derived from the previous block hash and height. Unique and unpredictable per block.', S.purple),
              ('02', 'Inference', 'The miner\'s local Ollama instance processes the challenge, generating a unique AI response.', S.blue),
              ('03', 'Commit', 'Response hash embedded in coinbase OP_RETURN as a 41-byte AIPR proof, permanently on-chain.', S.green),
              ('04', 'Mine', 'Scrypt proof-of-work completes the block. AI proof is part of the block identity via Merkle root.', S.pink),
            ];
            final cols = c.maxWidth > 800 ? 4 : 2;
            final w = c.maxWidth / cols;
            return Wrap(
              children: [
                for (final s in steps)
                  SizedBox(
                    width: w,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: S.surface,
                        border: Border.all(color: S.border, width: 0.25),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradText(s.$1, size: 48, weight: FontWeight.w800, colors: [s.$4, s.$4.withValues(alpha: 0.4)]),
                          const SizedBox(height: 16),
                          Text(s.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(s.$3, style: const TextStyle(fontSize: 13, color: S.text2, height: 1.6)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),

          // RPC
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader('AI RPC Commands', 'Seven AI-powered commands built directly into the node.', center: false),
                    Container(
                      decoration: BoxDecoration(color: S.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: S.border, width: 0.5)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          color: S.surface2,
                          child: const Row(children: [
                            SizedBox(width: 260, child: Text('COMMAND', style: TextStyle(fontSize: 10.5, color: S.text3, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
                            Expanded(child: Text('DESCRIPTION', style: TextStyle(fontSize: 10.5, color: S.text3, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
                          ]),
                        ),
                        for (final c in [
                          ('getaiinfo', 'AI subsystem status, Ollama connection, models'),
                          ('getaichallenge', 'Current AI challenge for the next block'),
                          ('getaiproof <hash>', 'Extract AI proof from a block'),
                          ('estimateaifee [urgency]', 'AI fee estimation (low / normal / high)'),
                          ('analyzaiblock <hash>', 'AI analysis of block content'),
                          ('analyzaimempool', 'AI mempool congestion analysis'),
                          ('analyzainetwork', 'AI network health report'),
                        ])
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: S.border, width: 0.5))),
                            child: Row(children: [
                              SizedBox(width: 260, child: Text(c.$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: S.green))),
                              Expanded(child: Text(c.$2, style: const TextStyle(fontSize: 13.5, color: S.text2))),
                            ]),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Footer(),
        ],
      ),
    );
  }
}

// ============================================================
// DOWNLOAD
// ============================================================
class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                const SectionHeader('Download ShardCoin', 'Get the node software, wallet, or build from source.'),
                LayoutBuilder(builder: (ctx, c) {
                  final cards = [
                    ('ShardCoin Core', 'Full node daemon, CLI, transaction tool, and wallet. Linux aarch64. AI proof-of-work included.', 'Download v0.1.0', true, S.purple),
                    ('ShardWallet', 'Non-custodial PWA wallet. BIP39 seed phrases, client-side signing, runs in any browser.', 'View on GitHub', false, S.green),
                    ('Source Code', 'Build from source. Fork of Litecoin Core with AI proof-of-work and all features from genesis.', 'View on GitHub', false, S.blue),
                  ];
                  final cols = c.maxWidth > 800 ? 3 : 1;
                  final gap = 16.0;
                  final w = (c.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap, runSpacing: gap,
                    children: [
                      for (final d in cards)
                        SizedBox(
                          width: w,
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: S.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: S.border, width: 0.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40, height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: LinearGradient(colors: [d.$5, d.$5.withValues(alpha: 0.2)]),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(d.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                Text(d.$2, style: const TextStyle(fontSize: 13.5, color: S.text2, height: 1.6)),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: d.$4
                                      ? _gradBtn(d.$3)
                                      : _outlineBtn(d.$3),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: S.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: S.border, width: 0.5),
                  ),
                  child: const SelectableText(
                    '# Quick start\n'
                    '\$ tar xzf shardcoin-core-linux-aarch64.tar.gz && cd shardcoin-core\n\n'
                    '# Start the node\n'
                    '\$ ./shardcoind -daemon\n'
                    '\$ ./shardcoin-cli getblockchaininfo\n\n'
                    '# Mine with AI (requires Ollama)\n'
                    '\$ ollama serve &\n'
                    '\$ ./shardcoin-cli createwallet "main"\n'
                    '\$ ./shardcoin-cli -generate 1\n\n'
                    '# AI commands\n'
                    '\$ ./shardcoin-cli getaiinfo\n'
                    '\$ ./shardcoin-cli estimateaifee "normal"\n'
                    '\$ ./shardcoin-cli analyzainetwork',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: S.green, height: 1.8),
                  ),
                ),
                const SizedBox(height: 100),
                const Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NETWORK
// ============================================================
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});
  static const _p = [
    ('Ticker', 'SHRD'), ('Algorithm', 'Scrypt + AI Proof-of-Work'),
    ('Block Time', '2.5 minutes'), ('Max Supply', '~8,400,000 SHRD'),
    ('Block Reward', '5 SHRD (10% decay / 100k blocks)'),
    ('P2P Port', '7333'), ('RPC Port', '7332'),
    ('Address Prefix', 'S (bech32: shrd1...)'), ('BIP44 Coin Type', '1000'),
    ('P2PKH', '63'), ('P2SH', '5'), ('Bech32 HRP', 'shrd'),
    ('WIF', '191'), ('Magic', '0xd3a2c4e7'),
    ('BIP32 Public', '0x0488B21E'), ('BIP32 Private', '0x0488ADE4'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Network Parameters', 'Everything you need to integrate with ShardCoin.', center: false),
                Container(
                  decoration: BoxDecoration(color: S.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: S.border, width: 0.5)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: S.surface2,
                      child: const Row(children: [
                        SizedBox(width: 180, child: Text('PARAMETER', style: TextStyle(fontSize: 10.5, color: S.text3, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
                        Expanded(child: Text('VALUE', style: TextStyle(fontSize: 10.5, color: S.text3, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
                      ]),
                    ),
                    for (final p in _p)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: S.border, width: 0.5))),
                        child: Row(children: [
                          SizedBox(width: 180, child: Text(p.$1, style: const TextStyle(fontSize: 13.5, color: S.text2))),
                          Expanded(child: SelectableText(p.$2, style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5))),
                        ]),
                      ),
                  ]),
                ),
                const SizedBox(height: 100),
                const Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EXPLORER
// ============================================================
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});
  @override
  State<ExplorerPage> createState() => _ExplorerState();
}

class _ExplorerState extends State<ExplorerPage> {
  List<dynamic> _blocks = [];
  Map<String, dynamic>? _info;
  Map<String, dynamic>? _block;
  Map<String, dynamic>? _tx;
  bool _loading = true;
  final _search = TextEditingController();
  Timer? _timer;

  @override
  void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load()); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final r1 = await http.get(Uri.parse('http://node.local:4402/api/info'));
      final r2 = await http.get(Uri.parse('http://node.local:4402/api/blocks'));
      if (mounted) setState(() { _info = json.decode(r1.body); _blocks = json.decode(r2.body); _loading = false; _block = null; _tx = null; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadBlock(String h) async {
    try {
      final r = await http.get(Uri.parse('http://node.local:4402/api/block/$h'));
      if (mounted) setState(() { _block = json.decode(r.body); _tx = null; });
    } catch (_) {}
  }

  Future<void> _loadTx(String id) async {
    try {
      final r = await http.get(Uri.parse('http://node.local:4402/api/tx/$id'));
      if (mounted) setState(() => _tx = json.decode(r.body));
    } catch (_) {}
  }

  void _doSearch() {
    final q = _search.text.trim();
    if (q.isEmpty) { _load(); return; }
    if (RegExp(r'^\d+$').hasMatch(q)) {
      http.get(Uri.parse('http://node.local:4402/api/blockhash/$q')).then((r) {
        final d = json.decode(r.body);
        if (d['hash'] != null) _loadBlock(d['hash']);
      });
    } else if (q.length == 64 && RegExp(r'^[a-f0-9]+$').hasMatch(q)) {
      _loadBlock(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Search bar
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) => _doSearch(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by block height, hash, or txid...',
                      hintStyle: const TextStyle(color: S.text3, fontSize: 14),
                      filled: true, fillColor: S.surface,
                      prefixIcon: const Icon(Icons.search, color: S.text3, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: S.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: S.border, width: 0.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: S.purple)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _gradBtn('Search', small: true, onTap: _doSearch),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: S.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: S.border, width: 0.5)),
                  child: IconButton(icon: const Icon(Icons.refresh, color: S.text3, size: 18), onPressed: _load, splashRadius: 20),
                ),
              ]),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: S.purple, strokeWidth: 2))
                    : SingleChildScrollView(child: _tx != null ? _txView() : _block != null ? _blockView() : _homeView()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {VoidCallback? onTap, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: S.border, width: 0.5))),
      child: Row(children: [
        SizedBox(width: 150, child: Text(label, style: const TextStyle(fontSize: 13, color: S.text3))),
        Expanded(
          child: MouseRegion(
            cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.text,
            child: GestureDetector(
              onTap: onTap,
              child: SelectableText(value, style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: valueColor ?? (onTap != null ? S.purple : S.text))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _card(String title, List<Widget> children, {Color accent = S.green}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: S.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: S.border, width: 0.5)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(color: S.surface2, border: Border(bottom: BorderSide(color: S.border, width: 0.5))),
          child: Row(children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: accent)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        ...children,
      ]),
    );
  }

  Widget _homeView() {
    return Column(children: [
      if (_info != null) _card('Network Overview', [
        if (_info!['blocks'] != null) _row('Height', '${_info!['blocks']}'),
        if (_info!['difficulty'] != null) _row('Difficulty', '${_info!['difficulty']}'),
        if (_info!['chain'] != null) _row('Chain', '${_info!['chain']}'),
        if (_info!['bestblockhash'] != null) _row('Best Block', '${_info!['bestblockhash']}'),
        if (_info!['ai'] != null) ...[
          _row('AI Proof', _info!['ai']['enabled'] == true ? 'Enabled' : 'Disabled', valueColor: _info!['ai']['enabled'] == true ? S.green : S.text3),
          _row('Ollama', _info!['ai']['ollama_connected'] == true ? 'Connected' : 'Offline', valueColor: _info!['ai']['ollama_connected'] == true ? S.green : S.pink),
        ],
      ]),
      _card('Recent Blocks', [
        for (final b in _blocks)
          InkWell(
            onTap: () => _loadBlock(b['hash']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: S.border, width: 0.5))),
              child: Row(children: [
                SizedBox(width: 65, child: Text('#${b['height']}', style: const TextStyle(fontWeight: FontWeight.w700, color: S.green, fontFamily: 'monospace', fontSize: 13))),
                Expanded(child: Text('${b['hash']}'.substring(0, 28) + '...', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: S.text3), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 80, child: Text(DateTime.fromMillisecondsSinceEpoch(b['time'] * 1000).toLocal().toString().substring(11, 19), style: const TextStyle(fontSize: 12, color: S.text3, fontFamily: 'monospace'))),
                SizedBox(width: 50, child: Text('${b['tx']} tx', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                if (b['ai'] == true) Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: S.grad2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ]),
            ),
          ),
      ], accent: S.blue),
    ]);
  }

  Widget _blockView() {
    final b = _block!;
    return Column(children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.arrow_back_rounded, size: 16), label: const Text('Back to blocks', style: TextStyle(fontSize: 13)))),
      const SizedBox(height: 8),
      _card('Block #${b['height'] ?? '?'}', [
        _row('Hash', '${b['hash']}'),
        _row('Previous', b['previousblockhash'] ?? 'Genesis', onTap: b['previousblockhash'] != null ? () => _loadBlock(b['previousblockhash']) : null),
        _row('Time', DateTime.fromMillisecondsSinceEpoch(b['time'] * 1000).toLocal().toString()),
        _row('Difficulty', '${b['difficulty']}'),
        _row('Nonce', '${b['nonce']}'),
        _row('Transactions', '${(b['tx'] as List?)?.length ?? 0}'),
        _row('Size', '${b['size']} bytes'),
        _row('Weight', '${b['weight']}'),
      ]),
      if (b['ai_proof'] != null) _card('AI Proof', [
        _row('Status', 'Verified', valueColor: S.green),
        _row('Response Hash', '${b['ai_proof']['response_hash']}'),
        _row('Model Tag', '${b['ai_proof']['model_tag']}'),
      ], accent: S.purple),
      if (b['tx'] != null) _card('Transactions (${(b['tx'] as List).length})', [
        for (final txid in b['tx'])
          InkWell(
            onTap: () => _loadTx(txid),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(txid, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: S.purple)),
            ),
          ),
      ], accent: S.blue),
    ]);
  }

  Widget _txView() {
    final tx = _tx!;
    return Column(children: [
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(
        onPressed: () => setState(() => _tx = null),
        icon: const Icon(Icons.arrow_back_rounded, size: 16), label: const Text('Back to block', style: TextStyle(fontSize: 13)),
      )),
      const SizedBox(height: 8),
      _card('Transaction', [
        _row('TXID', '${tx['txid']}'),
        _row('Size', '${tx['size']} bytes'),
        _row('Version', '${tx['version']}'),
        _row('Locktime', '${tx['locktime']}'),
        if (tx['blockhash'] != null) _row('Block', '${tx['blockhash']}', onTap: () => _loadBlock(tx['blockhash'])),
      ]),
      if (tx['vin'] != null) _card('Inputs (${(tx['vin'] as List).length})', [
        for (final i in tx['vin'])
          _row(i['coinbase'] != null ? 'Coinbase' : '${i['txid']}'.substring(0, 16) + '...', i['coinbase'] != null ? '${i['coinbase']}'.substring(0, 40) + '...' : 'vout:${i['vout']}'),
      ], accent: S.purple),
      if (tx['vout'] != null) _card('Outputs (${(tx['vout'] as List).length})', [
        for (final o in tx['vout'])
          _row(o['scriptPubKey']?['address'] ?? o['scriptPubKey']?['type'] ?? 'unknown', '${o['value']} SHRD', valueColor: S.green),
      ], accent: S.green),
    ]);
  }
}
