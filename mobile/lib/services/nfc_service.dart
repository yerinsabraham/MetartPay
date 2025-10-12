

// NFCService temporarily disabled due to unstable package ecosystem
import '../utils/app_logger.dart';
class NFCService {
  Future<void> writeNfc(String uriString) async {
    AppLogger.w('NFC temporarily disabled');
  }

  Future<String?> readNfc() async {
    AppLogger.w('NFC temporarily disabled');
    return null;
  }
}

