import 'package:connectivity_plus/connectivity_plus.dart';

/// Interface para informações de rede
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementação de NetworkInfo usando connectivity_plus
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
}
