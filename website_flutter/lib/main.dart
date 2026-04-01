import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ShardCoinApp());
}

// -- Theme --
class ShardTheme {
  static const bg = Color(0xFF000000);
  static const bg2 = Color(0xFF09090B);
  static const surface = Color(0xFF0F0F13);
  static const surface2 = Color(0xFF16161D);
  static const border = Color(0xFF1C1C27);
  static const border2 = Color(0xFF2A2A3A);
  static const text = Color(0xFFFAFAFA);
  static const text2 = Color(0xFFA1A1AA);
  static const text3 = Color(0xFF71717A);
  static const green = Color(0xFF14F195);
  static const purple = Color(0xFF9945FF);
  static const blue = Color(0xFF4DA2FF);
  static const gradient = [purple, green];
  static const gradient3 = [purple, blue, green];
}

class ShardCoinApp extends StatelessWidget {
  const ShardCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShardCoin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: ShardTheme.bg,
        colorScheme: const ColorScheme.dark(
          primary: ShardTheme.purple,
          secondary: ShardTheme.green,
          surface: ShardTheme.surface,
        ),
      ),
      home: const ShardCoinSite(),
    );
  }
}

class ShardCoinSite extends StatefulWidget {
  const ShardCoinSite({super.key});
  @override
  State<ShardCoinSite> createState() => _ShardCoinSiteState();
}

class _ShardCoinSiteState extends State<ShardCoinSite> {
  int _currentTab = 0;
  final _tabs = ['Home', 'Technology', 'Download', 'Network', 'Explorer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNav(),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xCC000000),
        border: Border(bottom: BorderSide(color: ShardTheme.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Logo
            GestureDetector(
              onTap: () => setState(() => _currentTab = 0),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(colors: ShardTheme.gradient),
                    ),
                    child: const Center(
                      child: Text('S', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('ShardCoin', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Tabs
            Expanded(
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = i == _currentTab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton(
                      onPressed: () => setState(() => _currentTab = i),
                      style: TextButton.styleFrom(
                        backgroundColor: active ? ShardTheme.surface2 : Colors.transparent,
                        foregroundColor: active ? ShardTheme.text : ShardTheme.text3,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(_tabs[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  );
                }),
              ),
            ),
            // CTA
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: ShardTheme.gradient),
              ),
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('GitHub', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentTab) {
      case 0: return const HomePage();
      case 1: return const TechnologyPage();
      case 2: return const DownloadPage();
      case 3: return const NetworkPage();
      case 4: return const ExplorerPage();
      default: return const HomePage();
    }
  }
}

// -- Shared Widgets --
class GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  const GradientText(this.text, {super.key, this.fontSize = 48, this.fontWeight = FontWeight.w800});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(colors: ShardTheme.gradient3).createShader(bounds),
      child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: Colors.white, height: 1.1)),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const StatCard({super.key, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        color: ShardTheme.bg2,
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: ShardTheme.text3, letterSpacing: 1, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String icon, title, description;
  final Color color;
  const FeatureCard({super.key, required this.icon, required this.title, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ShardTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ShardTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, color: ShardTheme.text2, height: 1.5)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  final bool center;
  const SectionTitle({super.key, required this.title, required this.subtitle, this.center = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        SizedBox(
          width: 640,
          child: Text(subtitle, style: const TextStyle(fontSize: 16, color: ShardTheme.text2, height: 1.6),
              textAlign: center ? TextAlign.center : TextAlign.start),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: ShardTheme.border))),
      child: Column(
        children: [
          Wrap(
            spacing: 24,
            children: [
              _link('GitHub'),
              _link('Releases'),
              _link('ShardWallet'),
              _link('Chain Data'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('ShardCoin is open source under the MIT license.', style: TextStyle(fontSize: 12, color: ShardTheme.text3)),
        ],
      ),
    );
  }

  Widget _link(String text) => Text(text, style: const TextStyle(fontSize: 14, color: ShardTheme.text2));
}

// -- HOME PAGE --
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 80),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [ShardTheme.purple.withValues(alpha: 0.12), Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: ShardTheme.surface2,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: ShardTheme.border2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: ShardTheme.green)),
                      const SizedBox(width: 8),
                      const Text('AI-Native Blockchain', style: TextStyle(fontSize: 13, color: ShardTheme.text2)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Powerful for miners.', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1.1)),
                const GradientText('Intelligent by design.'),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 560,
                  child: Text(
                    'ShardCoin is the first cryptocurrency where every block is proof of artificial intelligence. Scrypt mining meets local AI inference via Ollama.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: ShardTheme.text2, height: 1.7),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: ShardTheme.gradient),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        child: Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: ShardTheme.surface2,
                        border: Border.all(color: ShardTheme.border2),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        child: Text('Read Whitepaper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Bar
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: ShardTheme.border), bottom: BorderSide(color: ShardTheme.border))),
            child: const Row(
              children: [
                StatCard(value: '5 SHRD', label: 'BLOCK REWARD', color: ShardTheme.green),
                StatCard(value: '~8.4M', label: 'MAX SUPPLY', color: ShardTheme.purple),
                StatCard(value: '2.5 min', label: 'BLOCK TIME', color: ShardTheme.blue),
                StatCard(value: 'Scrypt+AI', label: 'ALGORITHM', color: ShardTheme.green),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(80),
            child: Column(
              children: [
                const SectionTitle(title: 'Built for the AI era', subtitle: 'ShardCoin combines battle-tested blockchain security with AI inference, creating a network that rewards running AI infrastructure.'),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: const [
                    SizedBox(width: 370, child: FeatureCard(icon: '\u2B22', title: 'AI Proof-of-Work', description: 'Every block includes a cryptographic proof of AI inference. Miners query local Ollama models and commit the response hash to the chain.', color: ShardTheme.purple)),
                    SizedBox(width: 370, child: FeatureCard(icon: '\u26A1', title: 'AI Fee Estimation', description: 'The AI analyzes mempool conditions in real-time and recommends optimal transaction fees based on current demand and urgency.', color: ShardTheme.green)),
                    SizedBox(width: 370, child: FeatureCard(icon: '\u{1F4CA}', title: 'AI Network Analysis', description: 'Built-in AI commands analyze blocks, mempool state, and overall network health with insights no traditional node can offer.', color: ShardTheme.blue)),
                    SizedBox(width: 370, child: FeatureCard(icon: '\u{1F512}', title: 'Privacy with MWEB', description: 'Optional Mimblewimble Extension Blocks provide confidential transactions with hidden amounts via Pedersen commitments.', color: ShardTheme.purple)),
                    SizedBox(width: 370, child: FeatureCard(icon: '\u{1F333}', title: 'Taproot from Genesis', description: 'Schnorr signatures, MAST, and key-path spending active from block 0. No activation delays, no technical debt.', color: ShardTheme.green)),
                    SizedBox(width: 370, child: FeatureCard(icon: '\u{1F4C9}', title: 'Smooth Emission Decay', description: 'Block rewards decrease 10% every 100,000 blocks instead of abrupt halvings. Predictable supply, no mining revenue shocks.', color: ShardTheme.blue)),
                  ],
                ),
              ],
            ),
          ),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// -- TECHNOLOGY PAGE --
class TechnologyPage extends StatelessWidget {
  const TechnologyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
            child: Column(
              children: [
                const SectionTitle(title: 'How AI Mining Works', subtitle: 'Four steps transform a standard block into an AI-verified unit of work.'),
              ],
            ),
          ),
          // Steps
          Row(
            children: [
              for (final s in [
                ('01', 'Challenge', 'A deterministic prompt derived from the previous block hash and height. Each block gets a unique challenge.'),
                ('02', 'Inference', 'The miner\'s local Ollama instance runs the challenge through a language model, generating a unique response.'),
                ('03', 'Commit', 'The response hash is embedded in the coinbase OP_RETURN as a 41-byte AIPR proof on-chain.'),
                ('04', 'Mine', 'Standard Scrypt proof-of-work completes the block. The AI proof becomes part of the block via Merkle root.'),
              ])
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    color: ShardTheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(s.$1, fontSize: 40, fontWeight: FontWeight.w700),
                        const SizedBox(height: 16),
                        Text(s.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(s.$3, style: const TextStyle(fontSize: 13, color: ShardTheme.text2, height: 1.5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // RPC Table
          Padding(
            padding: const EdgeInsets.all(80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'AI RPC Commands', subtitle: 'Seven AI-powered commands built directly into the node.', center: false),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: ShardTheme.border), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (final cmd in [
                        ('getaiinfo', 'AI subsystem status, Ollama connection, available models'),
                        ('getaichallenge', 'Current AI challenge prompt for the next block'),
                        ('getaiproof <hash>', 'Extract AI proof from a specific block'),
                        ('estimateaifee [urgency]', 'AI-powered fee estimation (low / normal / high)'),
                        ('analyzaiblock <hash>', 'AI analysis of block content and significance'),
                        ('analyzaimempool', 'AI mempool congestion and fee market analysis'),
                        ('analyzainetwork', 'AI comprehensive network health report'),
                      ])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ShardTheme.border))),
                          child: Row(
                            children: [
                              SizedBox(width: 260, child: Text(cmd.$1, style: const TextStyle(fontFamily: 'monospace', fontSize: 14))),
                              Expanded(child: Text(cmd.$2, style: const TextStyle(fontSize: 14, color: ShardTheme.text2))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// -- DOWNLOAD PAGE --
class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(80),
      child: Column(
        children: [
          const SectionTitle(title: 'Download ShardCoin', subtitle: 'Get the node software, wallet, or build from source.'),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _dlCard('ShardCoin Core', 'Full node daemon, CLI client, transaction tool, and wallet utility. Linux aarch64.', 'Download v0.1.0', true),
              _dlCard('ShardWallet', 'Non-custodial PWA wallet. BIP39 seed phrases, client-side signing, runs in any browser.', 'View on GitHub', false),
              _dlCard('Source Code', 'Build from source. Fork of Litecoin Core with AI proof-of-work and all features from genesis.', 'View on GitHub', false),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: ShardTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShardTheme.border)),
            child: const SelectableText(
              '# Quick start\n'
              'tar xzf shardcoin-core-linux-aarch64.tar.gz && cd shardcoin-core\n\n'
              '# Start the node\n'
              './shardcoind -daemon\n'
              './shardcoin-cli getblockchaininfo\n\n'
              '# Mine with AI (requires Ollama)\n'
              'ollama serve &\n'
              './shardcoin-cli createwallet "main"\n'
              './shardcoin-cli -generate 1\n\n'
              '# AI-powered commands\n'
              './shardcoin-cli getaiinfo\n'
              './shardcoin-cli estimateaifee "normal"\n'
              './shardcoin-cli analyzainetwork',
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: ShardTheme.green, height: 1.8),
            ),
          ),
          const SizedBox(height: 80),
          const FooterWidget(),
        ],
      ),
    );
  }

  Widget _dlCard(String title, String desc, String btn, bool primary) {
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: ShardTheme.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ShardTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(desc, style: const TextStyle(fontSize: 14, color: ShardTheme.text2, height: 1.5)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: primary ? const LinearGradient(colors: ShardTheme.gradient) : null,
                color: primary ? null : ShardTheme.surface2,
                border: primary ? null : Border.all(color: ShardTheme.border2),
              ),
              child: Text(btn, textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primary ? Colors.black : ShardTheme.text)),
            ),
          ],
        ),
      ),
    );
  }
}

// -- NETWORK PAGE --
class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});
  static const _params = [
    ('Ticker', 'SHRD'), ('Algorithm', 'Scrypt + AI Proof-of-Work (PoAIW)'),
    ('Block Time', '2.5 minutes'), ('Max Supply', '~8,400,000 SHRD'),
    ('Block Reward', '5 SHRD (10% decay every 100k blocks)'),
    ('P2P Port', '7333'), ('RPC Port', '7332'),
    ('Address Prefix', 'S (bech32: shrd1...)'), ('BIP44 Coin Type', '1000'),
    ('P2PKH Prefix', '63'), ('P2SH Prefix', '5'), ('Bech32 HRP', 'shrd'),
    ('WIF Prefix', '191'), ('Network Magic', '0xd3a2c4e7'),
    ('BIP32 Public', '0x0488B21E'), ('BIP32 Private', '0x0488ADE4'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Network Parameters', subtitle: 'Everything you need to integrate with ShardCoin.', center: false),
          Container(
            decoration: BoxDecoration(border: Border.all(color: ShardTheme.border), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ShardTheme.border))),
                  child: const Row(children: [
                    SizedBox(width: 200, child: Text('PARAMETER', style: TextStyle(fontSize: 11, color: ShardTheme.text3, letterSpacing: 1, fontWeight: FontWeight.w600))),
                    Expanded(child: Text('VALUE', style: TextStyle(fontSize: 11, color: ShardTheme.text3, letterSpacing: 1, fontWeight: FontWeight.w600))),
                  ]),
                ),
                for (final p in _params)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ShardTheme.border))),
                    child: Row(children: [
                      SizedBox(width: 200, child: Text(p.$1, style: const TextStyle(fontSize: 14))),
                      Expanded(child: Text(p.$2, style: const TextStyle(fontFamily: 'monospace', fontSize: 14))),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// -- EXPLORER PAGE --
class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});
  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  List<dynamic> _blocks = [];
  Map<String, dynamic>? _info;
  Map<String, dynamic>? _selectedBlock;
  Map<String, dynamic>? _selectedTx;
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final infoRes = await http.get(Uri.parse('http://node.local:4402/api/info'));
      final blocksRes = await http.get(Uri.parse('http://node.local:4402/api/blocks'));
      setState(() {
        _info = json.decode(infoRes.body);
        _blocks = json.decode(blocksRes.body);
        _loading = false;
        _selectedBlock = null;
        _selectedTx = null;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _loadBlock(String hash) async {
    try {
      final res = await http.get(Uri.parse('http://node.local:4402/api/block/$hash'));
      setState(() { _selectedBlock = json.decode(res.body); _selectedTx = null; });
    } catch (_) {}
  }

  Future<void> _loadTx(String txid) async {
    try {
      final res = await http.get(Uri.parse('http://node.local:4402/api/tx/$txid'));
      setState(() { _selectedTx = json.decode(res.body); });
    } catch (_) {}
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) { _loadData(); return; }
    if (RegExp(r'^\d+$').hasMatch(q)) {
      http.get(Uri.parse('http://node.local:4402/api/blockhash/$q')).then((r) {
        final data = json.decode(r.body);
        if (data['hash'] != null) _loadBlock(data['hash']);
      });
    } else if (q.length == 64 && RegExp(r'^[a-f0-9]+$').hasMatch(q)) {
      _loadBlock(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Search
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Search by block height, hash, or txid...',
                  hintStyle: const TextStyle(color: ShardTheme.text3),
                  filled: true, fillColor: ShardTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ShardTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ShardTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: ShardTheme.purple)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: ShardTheme.gradient)),
              child: TextButton(
                onPressed: _search,
                child: const Text('Search', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: ShardTheme.text3),
              onPressed: _loadData,
            ),
          ]),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ShardTheme.purple))
                : SingleChildScrollView(child: _selectedTx != null ? _buildTxView() : _selectedBlock != null ? _buildBlockView() : _buildHomeView()),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ShardTheme.border))),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(fontSize: 13, color: ShardTheme.text3))),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: SelectableText(value, style: TextStyle(
                fontSize: 13, fontFamily: 'monospace',
                color: onTap != null ? ShardTheme.purple : ShardTheme.text,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: ShardTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ShardTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ShardTheme.green))),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    return Column(
      children: [
        if (_info != null) _card('Network', [
          if (_info!['blocks'] != null) _infoRow('Height', '${_info!['blocks']}'),
          if (_info!['difficulty'] != null) _infoRow('Difficulty', '${_info!['difficulty']}'),
          if (_info!['chain'] != null) _infoRow('Chain', '${_info!['chain']}'),
          if (_info!['bestblockhash'] != null) _infoRow('Best Block', '${_info!['bestblockhash']}'),
          if (_info!['ai'] != null) ...[
            _infoRow('AI Proof', _info!['ai']['enabled'] == true ? 'Enabled' : 'Disabled'),
            _infoRow('Ollama', _info!['ai']['ollama_connected'] == true ? 'Connected' : 'Offline'),
          ],
        ]),
        _card('Recent Blocks', [
          for (final b in _blocks)
            InkWell(
              onTap: () => _loadBlock(b['hash']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ShardTheme.border))),
                child: Row(children: [
                  SizedBox(width: 70, child: Text('#${b['height']}', style: const TextStyle(fontWeight: FontWeight.w700, color: ShardTheme.green, fontFamily: 'monospace'))),
                  Expanded(child: Text('${b['hash']}'.substring(0, 32) + '...', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: ShardTheme.text3))),
                  SizedBox(width: 90, child: Text(DateTime.fromMillisecondsSinceEpoch(b['time'] * 1000).toLocal().toString().substring(11, 19), style: const TextStyle(fontSize: 12, color: ShardTheme.text3))),
                  SizedBox(width: 60, child: Text('${b['tx']} tx', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  if (b['ai'] == true) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: ShardTheme.purple, borderRadius: BorderRadius.circular(10)), child: const Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _buildBlockView() {
    final b = _selectedBlock!;
    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _loadData, icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Back'))),
        _card('Block #${b['height'] ?? '?'}', [
          _infoRow('Hash', '${b['hash']}'),
          _infoRow('Previous', b['previousblockhash'] ?? 'Genesis', onTap: b['previousblockhash'] != null ? () => _loadBlock(b['previousblockhash']) : null),
          _infoRow('Time', DateTime.fromMillisecondsSinceEpoch(b['time'] * 1000).toLocal().toString()),
          _infoRow('Difficulty', '${b['difficulty']}'),
          _infoRow('Nonce', '${b['nonce']}'),
          _infoRow('Transactions', '${(b['tx'] as List?)?.length ?? 0}'),
          _infoRow('Size', '${b['size']} bytes'),
          _infoRow('Weight', '${b['weight']}'),
          if (b['ai_proof'] != null) ...[
            _infoRow('AI Proof', 'Yes'),
            _infoRow('Response Hash', '${b['ai_proof']['response_hash']}'),
            _infoRow('Model Tag', '${b['ai_proof']['model_tag']}'),
          ],
        ]),
        if (b['tx'] != null) _card('Transactions', [
          for (final txid in b['tx'])
            InkWell(
              onTap: () => _loadTx(txid),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(txid, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: ShardTheme.purple)),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _buildTxView() {
    final tx = _selectedTx!;
    return Column(
      children: [
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          onPressed: () => setState(() => _selectedTx = null),
          icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Back'),
        )),
        _card('Transaction', [
          _infoRow('TXID', '${tx['txid']}'),
          _infoRow('Size', '${tx['size']} bytes'),
          _infoRow('Version', '${tx['version']}'),
          _infoRow('Locktime', '${tx['locktime']}'),
          if (tx['blockhash'] != null) _infoRow('Block', '${tx['blockhash']}', onTap: () => _loadBlock(tx['blockhash'])),
        ]),
        if (tx['vin'] != null) _card('Inputs (${(tx['vin'] as List).length})', [
          for (final inp in tx['vin'])
            _infoRow(
              inp['coinbase'] != null ? 'Coinbase' : '${inp['txid']}'.substring(0, 16) + '...',
              inp['coinbase'] != null ? '${inp['coinbase']}'.substring(0, 40) + '...' : 'vout:${inp['vout']}',
            ),
        ]),
        if (tx['vout'] != null) _card('Outputs (${(tx['vout'] as List).length})', [
          for (final out in tx['vout'])
            _infoRow(
              out['scriptPubKey']?['address'] ?? out['scriptPubKey']?['type'] ?? 'unknown',
              '${out['value']} SHRD',
            ),
        ]),
      ],
    );
  }
}
