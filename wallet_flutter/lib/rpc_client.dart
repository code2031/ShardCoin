import 'dart:convert';
import 'package:http/http.dart' as http;

class RpcException implements Exception {
  final String message;
  RpcException(this.message);
  @override
  String toString() => message;
}

class RpcClient {
  final String host;
  final int port;
  final String user;
  final String password;

  RpcClient({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
  });

  Future<dynamic> call(String method, [List<dynamic> params = const []]) async {
    final uri = Uri.parse('http://$host:$port');
    final credentials = base64Encode(utf8.encode('$user:$password'));
    final body = jsonEncode({
      'jsonrpc': '1.0',
      'id': 'wallet',
      'method': method,
      'params': params,
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (data['error'] != null) {
      throw RpcException(data['error']['message'] ?? 'RPC error');
    }
    return data['result'];
  }

  Future<Map<String, dynamic>> getWalletInfo() async {
    return Map<String, dynamic>.from(await call('getwalletinfo'));
  }

  Future<double> getBalance() async {
    final result = await call('getbalance');
    return (result as num).toDouble();
  }

  Future<String> getNewAddress() async {
    return await call('getnewaddress');
  }

  Future<List<dynamic>> getAddressesByLabel(String label) async {
    try {
      final result = await call('getaddressesbylabel', [label]);
      return (result as Map).keys.toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listTransactions({int count = 20}) async {
    final result = await call('listtransactions', ['*', count, 0, true]);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<String> sendToAddress(String address, double amount, String comment) async {
    return await call('sendtoaddress', [address, amount, comment]);
  }

  Future<Map<String, dynamic>> getBlockchainInfo() async {
    return Map<String, dynamic>.from(await call('getblockchaininfo'));
  }

  Future<List<String>> listWallets() async {
    return List<String>.from(await call('listwallets'));
  }

  Future<void> loadWallet(String name) async {
    await call('loadwallet', [name]);
  }

  Future<void> createWallet(String name) async {
    await call('createwallet', [name]);
  }

  Future<Map<String, dynamic>> validateAddress(String address) async {
    return Map<String, dynamic>.from(await call('validateaddress', [address]));
  }

  Future<double> estimateSmartFee(int confTarget) async {
    try {
      final result = await call('estimatesmartfee', [confTarget]);
      if (result['feerate'] != null) {
        return (result['feerate'] as num).toDouble();
      }
    } catch (_) {}
    return 0.0001;
  }
}
