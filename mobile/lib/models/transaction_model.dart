class TransactionModel {
  final String id;
  final String txHash;
  final String fromAddress;
  final String toAddress;
  final double amountCrypto;
  final String cryptoCurrency;
  final String network;
  final String status;
  final String? confirmedAt;
  final String? observedAt;
  final int? blockNumber;
  final int? confirmations;
  final int? requiredConfirmations;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    required this.id,
    required this.txHash,
    required this.fromAddress,
    required this.toAddress,
    required this.amountCrypto,
    required this.cryptoCurrency,
    required this.network,
    required this.status,
    this.confirmedAt,
    this.observedAt,
    this.blockNumber,
    this.confirmations,
    this.requiredConfirmations,
    this.metadata,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      txHash: json['txHash'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      amountCrypto: (json['amountCrypto'] is num) ? (json['amountCrypto'] as num).toDouble() : double.tryParse('${json['amountCrypto']}') ?? 0.0,
      cryptoCurrency: json['cryptoCurrency'] ?? '',
      network: json['network'] ?? '',
      status: json['status'] ?? 'pending',
      confirmedAt: json['confirmedAt'],
      observedAt: json['observedAt'],
      blockNumber: json['blockNumber'] != null ? int.tryParse('${json['blockNumber']}') : null,
      confirmations: json['confirmations'] != null ? int.tryParse('${json['confirmations']}') : null,
      requiredConfirmations: json['requiredConfirmations'] != null ? int.tryParse('${json['requiredConfirmations']}') : null,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }
}
