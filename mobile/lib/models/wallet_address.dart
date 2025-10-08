class WalletAddress {
  final String id;
  final String merchantId;
  final String network;
  final String address;
  final DateTime createdAt;
  final bool isActive;

  WalletAddress({
    required this.id,
    required this.merchantId,
    required this.network,
    required this.address,
    required this.createdAt,
    this.isActive = true,
  });

  factory WalletAddress.fromJson(Map<String, dynamic> json) {
    return WalletAddress(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String,
      network: json['network'] as String,
      address: json['address'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'network': network,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return 'WalletAddress(id: $id, network: $network, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletAddress &&
        other.id == id &&
        other.merchantId == merchantId &&
        other.network == network &&
        other.address == address;
  }

  @override
  int get hashCode {
    return Object.hash(id, merchantId, network, address);
  }
}