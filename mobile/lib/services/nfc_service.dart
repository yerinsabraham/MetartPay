

// NFCService temporarily disabled due to unstable package ecosystem
class NFCService {
  Future<void> writeNfc(String uriString) async {
    print('NFC temporarily disabled');
  }

  Future<String?> readNfc() async {
    print('NFC temporarily disabled');
    return null;
  }
}

