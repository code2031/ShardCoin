import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'rpc_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ShardCoinWallet(prefs: prefs));
}

class ShardCoinWallet extends StatefulWidget {
  final SharedPreferences prefs;
  const ShardCoinWallet({super.key, required this.prefs});

  @override
  State<ShardCoinWallet> createState() => _ShardCoinWalletState();
}

class _ShardCoinWalletState extends State<ShardCoinWallet> {
  RpcClient? _rpc;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _loadConnection();
  }

  void _loadConnection() {
    final host = widget.prefs.getString('rpc_host') ?? '127.0.0.1';
    final port = widget.prefs.getInt('rpc_port') ?? 7332;
    final user = widget.prefs.getString('rpc_user') ?? 'shardcoin';
    final pass = widget.prefs.getString('rpc_pass') ?? '';
    setState(() {
      _rpc = RpcClient(host: host, port: port, user: user, password: pass);
      _connected = pass.isNotEmpty;
    });
  }

  void _onSettingsSaved() {
    _loadConnection();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShardCoin Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        primaryColor: const Color(0xFF9945FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9945FF),
          secondary: Color(0xFF14F195),
          surface: Color(0xFF1A1A2E),
          error: Color(0xFFFF6B6B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: _connected && _rpc != null
          ? HomeScreen(rpc: _rpc!, prefs: widget.prefs, onDisconnect: _onSettingsSaved)
          : SettingsScreen(prefs: widget.prefs, onSaved: _onSettingsSaved, isSetup: true),
    );
  }
}
