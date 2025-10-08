class Merchant {
  final String id;
  final String userId;
  
  // Business Information
  final String businessName;
  final String industry;
  final String contactEmail;
  final String? businessAddress;
  
  // KYC Information
  final String fullName;
  final String? idNumber;
  final String? bvn;
  final String? address;
  final String kycStatus;
  final bool isSetupComplete;
  
  // Bank Account Information
  final String bankAccountNumber;
  final String bankName;
  final String bankAccountName;
  
  // Wallet Information
  final Map<String, String> walletAddresses; // {network: address}
  final double totalBalance;
  final double availableBalance;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Merchant({
    required this.id,
    required this.userId,
    required this.businessName,
    this.industry = '',
    this.contactEmail = '',
    this.businessAddress,
    required this.fullName,
    this.idNumber,
    this.bvn,
    this.address,
    required this.kycStatus,
    this.isSetupComplete = false,
    required this.bankAccountNumber,
    required this.bankName,
    required this.bankAccountName,
    this.walletAddresses = const {},
    this.totalBalance = 0.0,
    this.availableBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      businessName: json['businessName'] ?? '',
      industry: json['industry'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      businessAddress: json['businessAddress'],
      fullName: json['fullName'] ?? '',
      idNumber: json['idNumber'],
      bvn: json['bvn'],
      address: json['address'],
      kycStatus: json['kycStatus'] ?? 'pending',
      isSetupComplete: json['isSetupComplete'] ?? false,
      bankAccountNumber: json['bankAccountNumber'] ?? '',
      bankName: json['bankName'] ?? '',
      bankAccountName: json['bankAccountName'] ?? '',
      walletAddresses: Map<String, String>.from(json['walletAddresses'] ?? {}),
      totalBalance: (json['totalBalance'] ?? 0.0).toDouble(),
      availableBalance: (json['availableBalance'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'industry': industry,
      'contactEmail': contactEmail,
      'businessAddress': businessAddress,
      'fullName': fullName,
      'idNumber': idNumber,
      'bvn': bvn,
      'address': address,
      'kycStatus': kycStatus,
      'isSetupComplete': isSetupComplete,
      'bankAccountNumber': bankAccountNumber,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'walletAddresses': walletAddresses,
      'totalBalance': totalBalance,
      'availableBalance': availableBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Merchant copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? industry,
    String? contactEmail,
    String? businessAddress,
    String? fullName,
    String? idNumber,
    String? bvn,
    String? address,
    String? kycStatus,
    bool? isSetupComplete,
    String? bankAccountNumber,
    String? bankName,
    String? bankAccountName,
    Map<String, String>? walletAddresses,
    double? totalBalance,
    double? availableBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Merchant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      industry: industry ?? this.industry,
      contactEmail: contactEmail ?? this.contactEmail,
      businessAddress: businessAddress ?? this.businessAddress,
      fullName: fullName ?? this.fullName,
      idNumber: idNumber ?? this.idNumber,
      bvn: bvn ?? this.bvn,
      address: address ?? this.address,
      kycStatus: kycStatus ?? this.kycStatus,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      walletAddresses: walletAddresses ?? this.walletAddresses,
      totalBalance: totalBalance ?? this.totalBalance,
      availableBalance: availableBalance ?? this.availableBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Invoice {
  final String id;
  final String merchantId;
  final String reference;
  final double amountNaira;
  final double amountCrypto;
  final String cryptoSymbol;
  final String chain;
  final String receivingAddress;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? txHash;
  final double feeNaira;
  final double fxRate;
  final Map<String, dynamic>? metadata;

  Invoice({
    required this.id,
    required this.merchantId,
    required this.reference,
    required this.amountNaira,
    required this.amountCrypto,
    required this.cryptoSymbol,
    required this.chain,
    required this.receivingAddress,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.txHash,
    required this.feeNaira,
    required this.fxRate,
    this.metadata,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      merchantId: json['merchantId'] ?? '',
      reference: json['reference'],
      amountNaira: (json['amountNaira'] as num).toDouble(),
      amountCrypto: (json['amountCrypto'] as num).toDouble(),
      cryptoSymbol: json['cryptoSymbol'],
      chain: json['chain'],
      receivingAddress: json['receivingAddress'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      txHash: json['txHash'],
      feeNaira: (json['feeNaira'] as num?)?.toDouble() ?? 0.0,
      fxRate: (json['fxRate'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'reference': reference,
      'amountNaira': amountNaira,
      'amountCrypto': amountCrypto,
      'cryptoSymbol': cryptoSymbol,
      'chain': chain,
      'receivingAddress': receivingAddress,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'txHash': txHash,
      'feeNaira': feeNaira,
      'fxRate': fxRate,
      'metadata': metadata,
    };
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isExpired => status == 'expired';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Awaiting Payment';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'expired':
        return 'Expired';
      default:
        return status.toUpperCase();
    }
  }

  String get chainDisplayName {
    switch (chain) {
      case 'ETH':
        return 'Ethereum';
      case 'BSC':
        return 'Binance Smart Chain';
      case 'SOL':
        return 'Solana';
      default:
        return chain;
    }
  }
}

class Transaction {
  final String id;
  final String merchantId;
  final String invoiceId;
  final String? paymentLinkId;
  final String type; // 'payment_received', 'withdrawal', 'fee', 'refund'
  final String status; // 'pending', 'completed', 'failed', 'cancelled'
  final double amountNaira;
  final double amountCrypto;
  final String cryptoSymbol;
  final String chain;
  final String? fromAddress;
  final String? toAddress;
  final String? txHash;
  final String? description;
  final double feeNaira;
  final double feeCrypto;
  final double fxRate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  Transaction({
    required this.id,
    required this.merchantId,
    required this.invoiceId,
    this.paymentLinkId,
    required this.type,
    required this.status,
    required this.amountNaira,
    required this.amountCrypto,
    required this.cryptoSymbol,
    required this.chain,
    this.fromAddress,
    this.toAddress,
    this.txHash,
    this.description,
    required this.feeNaira,
    required this.feeCrypto,
    required this.fxRate,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      merchantId: json['merchantId'],
      invoiceId: json['invoiceId'],
      paymentLinkId: json['paymentLinkId'],
      type: json['type'],
      status: json['status'],
      amountNaira: (json['amountNaira'] as num).toDouble(),
      amountCrypto: (json['amountCrypto'] as num).toDouble(),
      cryptoSymbol: json['cryptoSymbol'],
      chain: json['chain'],
      fromAddress: json['fromAddress'],
      toAddress: json['toAddress'],
      txHash: json['txHash'],
      description: json['description'],
      feeNaira: (json['feeNaira'] as num?)?.toDouble() ?? 0.0,
      feeCrypto: (json['feeCrypto'] as num?)?.toDouble() ?? 0.0,
      fxRate: (json['fxRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'invoiceId': invoiceId,
      'paymentLinkId': paymentLinkId,
      'type': type,
      'status': status,
      'amountNaira': amountNaira,
      'amountCrypto': amountCrypto,
      'cryptoSymbol': cryptoSymbol,
      'chain': chain,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'txHash': txHash,
      'description': description,
      'feeNaira': feeNaira,
      'feeCrypto': feeCrypto,
      'fxRate': fxRate,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  bool get isIncoming => type == 'payment_received';
  bool get isOutgoing => type == 'withdrawal';
  bool get isFee => type == 'fee';
  bool get isRefund => type == 'refund';

  String get typeDisplayName {
    switch (type) {
      case 'payment_received':
        return 'Payment Received';
      case 'withdrawal':
        return 'Withdrawal';
      case 'fee':
        return 'Transaction Fee';
      case 'refund':
        return 'Refund';
      default:
        return type.toUpperCase();
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }
}

class PaymentLink {
  final String id;
  final String merchantId;
  final String title;
  final String? description;
  final double amountNaira;
  final String? customerId;
  final String? customerEmail;
  final String? customerName;
  final bool isActive;
  final int? usageLimit;
  final int usageCount;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final List<String> invoiceIds; // Track all invoices created from this link

  PaymentLink({
    required this.id,
    required this.merchantId,
    required this.title,
    this.description,
    required this.amountNaira,
    this.customerId,
    this.customerEmail,
    this.customerName,
    this.isActive = true,
    this.usageLimit,
    this.usageCount = 0,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.invoiceIds = const [],
  });

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    return PaymentLink(
      id: json['id'],
      merchantId: json['merchantId'],
      title: json['title'],
      description: json['description'],
      amountNaira: (json['amountNaira'] as num).toDouble(),
      customerId: json['customerId'],
      customerEmail: json['customerEmail'],
      customerName: json['customerName'],
      isActive: json['isActive'] ?? true,
      usageLimit: json['usageLimit'],
      usageCount: json['usageCount'] ?? 0,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      metadata: json['metadata'],
      invoiceIds: List<String>.from(json['invoiceIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'title': title,
      'description': description,
      'amountNaira': amountNaira,
      'customerId': customerId,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'invoiceIds': invoiceIds,
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasReachedUsageLimit => usageLimit != null && usageCount >= usageLimit!;
  bool get canBeUsed => isActive && !isExpired && !hasReachedUsageLimit;

  String get url => 'https://metartpay.com/pay/$id';
}

class Customer {
  final String id;
  final String merchantId;
  final String email;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final DateTime? dateOfBirth;
  final String? gender;
  final String status; // 'active', 'inactive', 'blocked', 'vip'
  final String tier; // 'bronze', 'silver', 'gold', 'platinum'
  final String? notes;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final Map<String, String> socialMedia;
  
  // Transaction Statistics
  final int totalTransactions;
  final double totalSpentNaira;
  final double totalSpentUSD;
  final double averageTransactionAmount;
  final int transactionsThisMonth;
  final double spentThisMonth;
  final DateTime? firstTransactionAt;
  final DateTime? lastTransactionAt;
  
  // Engagement & Communication
  final DateTime? lastContactDate;
  final DateTime? lastLoginDate;
  final String? preferredContactMethod; // 'email', 'phone', 'sms', 'whatsapp'
  final bool isSubscribedToNewsletter;
  final bool allowsMarketingEmails;
  final bool allowsSMSMarketing;
  final String? referralSource;
  final String? referredBy;
  final int referralCount;
  
  // VIP & Scoring
  final bool isVIP;
  final int loyaltyScore; // 0-100
  final int riskScore; // 0-100
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.merchantId,
    required this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.dateOfBirth,
    this.gender,
    this.status = 'active',
    this.tier = 'bronze',
    this.notes,
    this.tags = const [],
    this.metadata = const {},
    this.socialMedia = const {},
    this.totalTransactions = 0,
    this.totalSpentNaira = 0.0,
    this.totalSpentUSD = 0.0,
    this.averageTransactionAmount = 0.0,
    this.transactionsThisMonth = 0,
    this.spentThisMonth = 0.0,
    this.firstTransactionAt,
    this.lastTransactionAt,
    this.lastContactDate,
    this.lastLoginDate,
    this.preferredContactMethod,
    this.isSubscribedToNewsletter = false,
    this.allowsMarketingEmails = true,
    this.allowsSMSMarketing = true,
    this.referralSource,
    this.referredBy,
    this.referralCount = 0,
    this.isVIP = false,
    this.loyaltyScore = 50,
    this.riskScore = 20,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      merchantId: json['merchantId'],
      email: json['email'],
      name: json['name'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      gender: json['gender'],
      status: json['status'] ?? 'active',
      tier: json['tier'] ?? 'bronze',
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      socialMedia: Map<String, String>.from(json['socialMedia'] ?? {}),
      totalTransactions: json['totalTransactions'] ?? 0,
      totalSpentNaira: (json['totalSpentNaira'] as num?)?.toDouble() ?? 0.0,
      totalSpentUSD: (json['totalSpentUSD'] as num?)?.toDouble() ?? 0.0,
      averageTransactionAmount: (json['averageTransactionAmount'] as num?)?.toDouble() ?? 0.0,
      transactionsThisMonth: json['transactionsThisMonth'] ?? 0,
      spentThisMonth: (json['spentThisMonth'] as num?)?.toDouble() ?? 0.0,
      firstTransactionAt: json['firstTransactionAt'] != null ? DateTime.parse(json['firstTransactionAt']) : null,
      lastTransactionAt: json['lastTransactionAt'] != null ? DateTime.parse(json['lastTransactionAt']) : null,
      lastContactDate: json['lastContactDate'] != null ? DateTime.parse(json['lastContactDate']) : null,
      lastLoginDate: json['lastLoginDate'] != null ? DateTime.parse(json['lastLoginDate']) : null,
      preferredContactMethod: json['preferredContactMethod'],
      isSubscribedToNewsletter: json['isSubscribedToNewsletter'] ?? false,
      allowsMarketingEmails: json['allowsMarketingEmails'] ?? true,
      allowsSMSMarketing: json['allowsSMSMarketing'] ?? true,
      referralSource: json['referralSource'],
      referredBy: json['referredBy'],
      referralCount: json['referralCount'] ?? 0,
      isVIP: json['isVIP'] ?? false,
      loyaltyScore: json['loyaltyScore'] ?? 50,
      riskScore: json['riskScore'] ?? 20,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'email': email,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'status': status,
      'tier': tier,
      'notes': notes,
      'tags': tags,
      'metadata': metadata,
      'socialMedia': socialMedia,
      'totalTransactions': totalTransactions,
      'totalSpentNaira': totalSpentNaira,
      'totalSpentUSD': totalSpentUSD,
      'averageTransactionAmount': averageTransactionAmount,
      'transactionsThisMonth': transactionsThisMonth,
      'spentThisMonth': spentThisMonth,
      'firstTransactionAt': firstTransactionAt?.toIso8601String(),
      'lastTransactionAt': lastTransactionAt?.toIso8601String(),
      'lastContactDate': lastContactDate?.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'preferredContactMethod': preferredContactMethod,
      'isSubscribedToNewsletter': isSubscribedToNewsletter,
      'allowsMarketingEmails': allowsMarketingEmails,
      'allowsSMSMarketing': allowsSMSMarketing,
      'referralSource': referralSource,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'isVIP': isVIP,
      'loyaltyScore': loyaltyScore,
      'riskScore': riskScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? merchantId,
    String? email,
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    DateTime? dateOfBirth,
    String? gender,
    String? status,
    String? tier,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    Map<String, String>? socialMedia,
    int? totalTransactions,
    double? totalSpentNaira,
    double? totalSpentUSD,
    double? averageTransactionAmount,
    int? transactionsThisMonth,
    double? spentThisMonth,
    DateTime? firstTransactionAt,
    DateTime? lastTransactionAt,
    DateTime? lastContactDate,
    DateTime? lastLoginDate,
    String? preferredContactMethod,
    bool? isSubscribedToNewsletter,
    bool? allowsMarketingEmails,
    bool? allowsSMSMarketing,
    String? referralSource,
    String? referredBy,
    int? referralCount,
    bool? isVIP,
    int? loyaltyScore,
    int? riskScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      email: email ?? this.email,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      socialMedia: socialMedia ?? this.socialMedia,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalSpentNaira: totalSpentNaira ?? this.totalSpentNaira,
      totalSpentUSD: totalSpentUSD ?? this.totalSpentUSD,
      averageTransactionAmount: averageTransactionAmount ?? this.averageTransactionAmount,
      transactionsThisMonth: transactionsThisMonth ?? this.transactionsThisMonth,
      spentThisMonth: spentThisMonth ?? this.spentThisMonth,
      firstTransactionAt: firstTransactionAt ?? this.firstTransactionAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      isSubscribedToNewsletter: isSubscribedToNewsletter ?? this.isSubscribedToNewsletter,
      allowsMarketingEmails: allowsMarketingEmails ?? this.allowsMarketingEmails,
      allowsSMSMarketing: allowsSMSMarketing ?? this.allowsSMSMarketing,
      referralSource: referralSource ?? this.referralSource,
      referredBy: referredBy ?? this.referredBy,
      referralCount: referralCount ?? this.referralCount,
      isVIP: isVIP ?? this.isVIP,
      loyaltyScore: loyaltyScore ?? this.loyaltyScore,
      riskScore: riskScore ?? this.riskScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Computed properties
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return email;
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name ?? displayName;
  }

  bool get isReturning => totalTransactions > 1;
  
  bool get isActive => status == 'active';
  
  // Computed transaction properties
  double get averageTransactionValue {
    if (totalTransactions > 0) {
      return totalSpentNaira / totalTransactions;
    }
    return 0.0;
  }
  
  DateTime? get lastTransactionDate => lastTransactionAt;
  
  // Attention tracking
  bool get requiresAttention {
    if (lastTransactionDate == null) return true;
    final daysSince = DateTime.now().difference(lastTransactionDate!).inDays;
    return daysSince > 30; // No transaction in 30+ days
  }
  
  int get daysSinceLastTransaction {
    if (lastTransactionDate == null) return 9999;
    return DateTime.now().difference(lastTransactionDate!).inDays;
  }
  
  String get customerValue {
    if (totalSpentNaira >= 1000000) return 'High Value';
    if (totalSpentNaira >= 100000) return 'Medium Value';
    if (totalSpentNaira >= 10000) return 'Regular';
    return 'New Customer';
  }

  String get tierColor {
    switch (tier) {
      case 'platinum':
        return '#E5E4E2'; // Platinum
      case 'gold':
        return '#FFD700'; // Gold
      case 'silver':
        return '#C0C0C0'; // Silver
      default:
        return '#CD7F32'; // Bronze
    }
  }

  String get statusColor {
    switch (status) {
      case 'active':
        return '#4CAF50'; // Green
      case 'inactive':
        return '#9E9E9E'; // Grey
      case 'blocked':
        return '#F44336'; // Red
      case 'vip':
        return '#9C27B0'; // Purple
      default:
        return '#2196F3'; // Blue
    }
  }



  String get engagementLevel {
    if (transactionsThisMonth >= 10) return 'Highly Active';
    if (transactionsThisMonth >= 5) return 'Active';
    if (transactionsThisMonth >= 1) return 'Moderate';
    if (daysSinceLastTransaction <= 7) return 'Recent';
    if (daysSinceLastTransaction <= 30) return 'Inactive';
    return 'Dormant';
  }
}

class AppNotification {
  final String id;
  final String merchantId;
  final String type; // 'kyc_update', 'payment_received', 'payment_confirmed', 'account_security', 'system'
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isArchived;
  final String priority; // 'low', 'normal', 'high', 'critical'
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledAt;
  final String? actionUrl;
  final String? actionText;

  AppNotification({
    required this.id,
    required this.merchantId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.isRead = false,
    this.isArchived = false,
    this.priority = 'normal',
    required this.createdAt,
    this.readAt,
    this.scheduledAt,
    this.actionUrl,
    this.actionText,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      merchantId: json['merchantId'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      data: json['data'],
      isRead: json['isRead'] ?? false,
      isArchived: json['isArchived'] ?? false,
      priority: json['priority'] ?? 'normal',
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      actionUrl: json['actionUrl'],
      actionText: json['actionText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'type': type,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'isRead': isRead,
      'isArchived': isArchived,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'actionUrl': actionUrl,
      'actionText': actionText,
    };
  }

  AppNotification copyWith({
    String? id,
    String? merchantId,
    String? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isArchived,
    String? priority,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? scheduledAt,
    String? actionUrl,
    String? actionText,
  }) {
    return AppNotification(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      actionUrl: actionUrl ?? this.actionUrl,
      actionText: actionText ?? this.actionText,
    );
  }

  bool get isCritical => priority == 'critical';
  bool get isHigh => priority == 'high';
  bool get isScheduled => scheduledAt != null;
  bool get hasAction => actionUrl != null && actionText != null;

  String get typeDisplayName {
    switch (type) {
      case 'kyc_update':
        return 'KYC Update';
      case 'payment_received':
        return 'Payment Received';
      case 'payment_confirmed':
        return 'Payment Confirmed';
      case 'account_security':
        return 'Security Alert';
      case 'system':
        return 'System Notification';
      default:
        return type.toUpperCase();
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low Priority';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High Priority';
      case 'critical':
        return 'Critical';
      default:
        return priority.toUpperCase();
    }
  }
}

class MerchantNotificationSettings {
  final String merchantId;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;
  final bool notifyOnPaymentReceived;
  final bool notifyOnPaymentConfirmed;
  final bool notifyOnKYCUpdate;
  final bool notifyOnSecurityEvents;
  final bool notifyOnSystemUpdates;
  final bool notifyOnLowBalance;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "08:00"
  final bool enableQuietHours;
  final DateTime updatedAt;

  MerchantNotificationSettings({
    required this.merchantId,
    this.enablePushNotifications = true,
    this.enableEmailNotifications = true,
    this.enableSMSNotifications = false,
    this.notifyOnPaymentReceived = true,
    this.notifyOnPaymentConfirmed = true,
    this.notifyOnKYCUpdate = true,
    this.notifyOnSecurityEvents = true,
    this.notifyOnSystemUpdates = true,
    this.notifyOnLowBalance = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.enableQuietHours = false,
    required this.updatedAt,
  });

  factory MerchantNotificationSettings.fromJson(Map<String, dynamic> json) {
    return MerchantNotificationSettings(
      merchantId: json['merchantId'],
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] ?? true,
      enableSMSNotifications: json['enableSMSNotifications'] ?? false,
      notifyOnPaymentReceived: json['notifyOnPaymentReceived'] ?? true,
      notifyOnPaymentConfirmed: json['notifyOnPaymentConfirmed'] ?? true,
      notifyOnKYCUpdate: json['notifyOnKYCUpdate'] ?? true,
      notifyOnSecurityEvents: json['notifyOnSecurityEvents'] ?? true,
      notifyOnSystemUpdates: json['notifyOnSystemUpdates'] ?? true,
      notifyOnLowBalance: json['notifyOnLowBalance'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
      enableQuietHours: json['enableQuietHours'] ?? false,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSMSNotifications': enableSMSNotifications,
      'notifyOnPaymentReceived': notifyOnPaymentReceived,
      'notifyOnPaymentConfirmed': notifyOnPaymentConfirmed,
      'notifyOnKYCUpdate': notifyOnKYCUpdate,
      'notifyOnSecurityEvents': notifyOnSecurityEvents,
      'notifyOnSystemUpdates': notifyOnSystemUpdates,
      'notifyOnLowBalance': notifyOnLowBalance,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'enableQuietHours': enableQuietHours,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MerchantNotificationSettings copyWith({
    String? merchantId,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSMSNotifications,
    bool? notifyOnPaymentReceived,
    bool? notifyOnPaymentConfirmed,
    bool? notifyOnKYCUpdate,
    bool? notifyOnSecurityEvents,
    bool? notifyOnSystemUpdates,
    bool? notifyOnLowBalance,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? enableQuietHours,
    DateTime? updatedAt,
  }) {
    return MerchantNotificationSettings(
      merchantId: merchantId ?? this.merchantId,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableSMSNotifications: enableSMSNotifications ?? this.enableSMSNotifications,
      notifyOnPaymentReceived: notifyOnPaymentReceived ?? this.notifyOnPaymentReceived,
      notifyOnPaymentConfirmed: notifyOnPaymentConfirmed ?? this.notifyOnPaymentConfirmed,
      notifyOnKYCUpdate: notifyOnKYCUpdate ?? this.notifyOnKYCUpdate,
      notifyOnSecurityEvents: notifyOnSecurityEvents ?? this.notifyOnSecurityEvents,
      notifyOnSystemUpdates: notifyOnSystemUpdates ?? this.notifyOnSystemUpdates,
      notifyOnLowBalance: notifyOnLowBalance ?? this.notifyOnLowBalance,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isInQuietHours() {
    if (!enableQuietHours) return false;
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Handle quiet hours that span midnight
    if (quietHoursStart.compareTo(quietHoursEnd) > 0) {
      return currentTime.compareTo(quietHoursStart) >= 0 || currentTime.compareTo(quietHoursEnd) < 0;
    } else {
      return currentTime.compareTo(quietHoursStart) >= 0 && currentTime.compareTo(quietHoursEnd) < 0;
    }
  }
}

// Security Models
class UserSession {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String deviceModel;
  final String operatingSystem;
  final String appVersion;
  final String ipAddress;
  final String location;
  final DateTime loginTime;
  final DateTime? lastActivity;
  final DateTime? logoutTime;
  final bool isActive;
  final String sessionToken;
  final Map<String, dynamic> metadata;

  UserSession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceModel,
    required this.operatingSystem,
    required this.appVersion,
    required this.ipAddress,
    required this.location,
    required this.loginTime,
    this.lastActivity,
    this.logoutTime,
    required this.isActive,
    required this.sessionToken,
    this.metadata = const {},
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      userId: json['userId'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      deviceModel: json['deviceModel'],
      operatingSystem: json['operatingSystem'],
      appVersion: json['appVersion'],
      ipAddress: json['ipAddress'],
      location: json['location'],
      loginTime: DateTime.parse(json['loginTime']),
      lastActivity: json['lastActivity'] != null ? DateTime.parse(json['lastActivity']) : null,
      logoutTime: json['logoutTime'] != null ? DateTime.parse(json['logoutTime']) : null,
      isActive: json['isActive'],
      sessionToken: json['sessionToken'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'operatingSystem': operatingSystem,
      'appVersion': appVersion,
      'ipAddress': ipAddress,
      'location': location,
      'loginTime': loginTime.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'logoutTime': logoutTime?.toIso8601String(),
      'isActive': isActive,
      'sessionToken': sessionToken,
      'metadata': metadata,
    };
  }

  UserSession copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceModel,
    String? operatingSystem,
    String? appVersion,
    String? ipAddress,
    String? location,
    DateTime? loginTime,
    DateTime? lastActivity,
    DateTime? logoutTime,
    bool? isActive,
    String? sessionToken,
    Map<String, dynamic>? metadata,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      appVersion: appVersion ?? this.appVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      loginTime: loginTime ?? this.loginTime,
      lastActivity: lastActivity ?? this.lastActivity,
      logoutTime: logoutTime ?? this.logoutTime,
      isActive: isActive ?? this.isActive,
      sessionToken: sessionToken ?? this.sessionToken,
      metadata: metadata ?? this.metadata,
    );
  }

  bool isExpired() {
    if (!isActive) return true;
    if (logoutTime != null) return true;
    
    // Session expires after 7 days of inactivity
    final lastActivityTime = lastActivity ?? loginTime;
    return DateTime.now().difference(lastActivityTime).inDays >= 7;
  }

  String get sessionDuration {
    final duration = DateTime.now().difference(loginTime);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class SecurityLog {
  final String id;
  final String userId;
  final String sessionId;
  final String eventType;
  final String eventDescription;
  final String severity; // low, medium, high, critical
  final String deviceId;
  final String ipAddress;
  final String? location;
  final Map<String, dynamic> eventData;
  final DateTime timestamp;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolution;

  SecurityLog({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.eventType,
    required this.eventDescription,
    required this.severity,
    required this.deviceId,
    required this.ipAddress,
    this.location,
    this.eventData = const {},
    required this.timestamp,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    this.resolution,
  });

  factory SecurityLog.fromJson(Map<String, dynamic> json) {
    return SecurityLog(
      id: json['id'],
      userId: json['userId'],
      sessionId: json['sessionId'],
      eventType: json['eventType'],
      eventDescription: json['eventDescription'],
      severity: json['severity'],
      deviceId: json['deviceId'],
      ipAddress: json['ipAddress'],
      location: json['location'],
      eventData: Map<String, dynamic>.from(json['eventData'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      isResolved: json['isResolved'] ?? false,
      resolvedBy: json['resolvedBy'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolution: json['resolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'eventType': eventType,
      'eventDescription': eventDescription,
      'severity': severity,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'location': location,
      'eventData': eventData,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
    };
  }

  SecurityLog copyWith({
    String? id,
    String? userId,
    String? sessionId,
    String? eventType,
    String? eventDescription,
    String? severity,
    String? deviceId,
    String? ipAddress,
    String? location,
    Map<String, dynamic>? eventData,
    DateTime? timestamp,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolution,
  }) {
    return SecurityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      eventDescription: eventDescription ?? this.eventDescription,
      severity: severity ?? this.severity,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      eventData: eventData ?? this.eventData,
      timestamp: timestamp ?? this.timestamp,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
    );
  }

  String get severityColor {
    switch (severity) {
      case 'critical':
        return 'red';
      case 'high':
        return 'orange';
      case 'medium':
        return 'yellow';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class BiometricSettings {
  final String userId;
  final bool enableBiometrics;
  final bool enableFingerprintAuth;
  final bool enableFaceAuth;
  final bool requireBiometricForLogin;
  final bool requireBiometricForTransactions;
  final bool requireBiometricForSensitiveActions;
  final DateTime updatedAt;
  final List<String> enrolledBiometrics;
  final int maxFailedAttempts;
  final Duration lockoutDuration;

  BiometricSettings({
    required this.userId,
    this.enableBiometrics = false,
    this.enableFingerprintAuth = false,
    this.enableFaceAuth = false,
    this.requireBiometricForLogin = false,
    this.requireBiometricForTransactions = false,
    this.requireBiometricForSensitiveActions = false,
    required this.updatedAt,
    this.enrolledBiometrics = const [],
    this.maxFailedAttempts = 3,
    this.lockoutDuration = const Duration(minutes: 5),
  });

  factory BiometricSettings.fromJson(Map<String, dynamic> json) {
    return BiometricSettings(
      userId: json['userId'],
      enableBiometrics: json['enableBiometrics'] ?? false,
      enableFingerprintAuth: json['enableFingerprintAuth'] ?? false,
      enableFaceAuth: json['enableFaceAuth'] ?? false,
      requireBiometricForLogin: json['requireBiometricForLogin'] ?? false,
      requireBiometricForTransactions: json['requireBiometricForTransactions'] ?? false,
      requireBiometricForSensitiveActions: json['requireBiometricForSensitiveActions'] ?? false,
      updatedAt: DateTime.parse(json['updatedAt']),
      enrolledBiometrics: List<String>.from(json['enrolledBiometrics'] ?? []),
      maxFailedAttempts: json['maxFailedAttempts'] ?? 3,
      lockoutDuration: Duration(milliseconds: json['lockoutDuration'] ?? 300000),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'enableBiometrics': enableBiometrics,
      'enableFingerprintAuth': enableFingerprintAuth,
      'enableFaceAuth': enableFaceAuth,
      'requireBiometricForLogin': requireBiometricForLogin,
      'requireBiometricForTransactions': requireBiometricForTransactions,
      'requireBiometricForSensitiveActions': requireBiometricForSensitiveActions,
      'updatedAt': updatedAt.toIso8601String(),
      'enrolledBiometrics': enrolledBiometrics,
      'maxFailedAttempts': maxFailedAttempts,
      'lockoutDuration': lockoutDuration.inMilliseconds,
    };
  }

  BiometricSettings copyWith({
    String? userId,
    bool? enableBiometrics,
    bool? enableFingerprintAuth,
    bool? enableFaceAuth,
    bool? requireBiometricForLogin,
    bool? requireBiometricForTransactions,
    bool? requireBiometricForSensitiveActions,
    DateTime? updatedAt,
    List<String>? enrolledBiometrics,
    int? maxFailedAttempts,
    Duration? lockoutDuration,
  }) {
    return BiometricSettings(
      userId: userId ?? this.userId,
      enableBiometrics: enableBiometrics ?? this.enableBiometrics,
      enableFingerprintAuth: enableFingerprintAuth ?? this.enableFingerprintAuth,
      enableFaceAuth: enableFaceAuth ?? this.enableFaceAuth,
      requireBiometricForLogin: requireBiometricForLogin ?? this.requireBiometricForLogin,
      requireBiometricForTransactions: requireBiometricForTransactions ?? this.requireBiometricForTransactions,
      requireBiometricForSensitiveActions: requireBiometricForSensitiveActions ?? this.requireBiometricForSensitiveActions,
      updatedAt: updatedAt ?? this.updatedAt,
      enrolledBiometrics: enrolledBiometrics ?? this.enrolledBiometrics,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lockoutDuration: lockoutDuration ?? this.lockoutDuration,
    );
  }

  bool get hasBiometricsEnabled => enableBiometrics && (enableFingerprintAuth || enableFaceAuth);
  bool get hasEnrolledBiometrics => enrolledBiometrics.isNotEmpty;
}

// Customer Management Models
class CustomerInteraction {
  final String id;
  final String customerId;
  final String merchantId;
  final String type; // 'email', 'phone', 'sms', 'meeting', 'support', 'marketing'
  final String subject;
  final String content;
  final String status; // 'pending', 'sent', 'delivered', 'read', 'replied', 'failed'
  final String direction; // 'inbound', 'outbound'
  final DateTime scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? repliedAt;
  final Map<String, dynamic> metadata;
  final String? attachments;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerInteraction({
    required this.id,
    required this.customerId,
    required this.merchantId,
    required this.type,
    required this.subject,
    required this.content,
    this.status = 'pending',
    this.direction = 'outbound',
    required this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.repliedAt,
    this.metadata = const {},
    this.attachments,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerInteraction.fromJson(Map<String, dynamic> json) {
    return CustomerInteraction(
      id: json['id'],
      customerId: json['customerId'],
      merchantId: json['merchantId'],
      type: json['type'],
      subject: json['subject'],
      content: json['content'],
      status: json['status'] ?? 'pending',
      direction: json['direction'] ?? 'outbound',
      scheduledAt: DateTime.parse(json['scheduledAt']),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      repliedAt: json['repliedAt'] != null ? DateTime.parse(json['repliedAt']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      attachments: json['attachments'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'merchantId': merchantId,
      'type': type,
      'subject': subject,
      'content': content,
      'status': status,
      'direction': direction,
      'scheduledAt': scheduledAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'repliedAt': repliedAt?.toIso8601String(),
      'metadata': metadata,
      'attachments': attachments,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CustomerInteraction copyWith({
    String? id,
    String? customerId,
    String? merchantId,
    String? type,
    String? subject,
    String? content,
    String? status,
    String? direction,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? repliedAt,
    Map<String, dynamic>? metadata,
    String? attachments,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerInteraction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      merchantId: merchantId ?? this.merchantId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      repliedAt: repliedAt ?? this.repliedAt,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter for backward compatibility with UI
  String? get notes => content;
  
  bool get isCompleted => status == 'delivered' || status == 'read' || status == 'replied';
  bool get hasFailed => status == 'failed';
  bool get isPending => status == 'pending';
  bool get isScheduled => scheduledAt.isAfter(DateTime.now());
  
  String get statusColor {
    switch (status) {
      case 'delivered':
      case 'read':
      case 'replied':
        return '#4CAF50'; // Green
      case 'sent':
        return '#2196F3'; // Blue
      case 'pending':
        return '#FF9800'; // Orange
      case 'failed':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String get typeIcon {
    switch (type) {
      case 'email':
        return 'email';
      case 'phone':
        return 'phone';
      case 'sms':
        return 'sms';
      case 'meeting':
        return 'event';
      case 'support':
        return 'support';
      case 'marketing':
        return 'campaign';
      default:
        return 'message';
    }
  }
}

class CustomerSegment {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final Map<String, dynamic> criteria;
  final List<String> customerIds;
  final int customerCount;
  final String type; // 'static', 'dynamic'
  final bool isActive;
  final String color;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerSegment({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.criteria,
    this.customerIds = const [],
    this.customerCount = 0,
    this.type = 'dynamic',
    this.isActive = true,
    this.color = '#2196F3',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerSegment.fromJson(Map<String, dynamic> json) {
    return CustomerSegment(
      id: json['id'],
      merchantId: json['merchantId'],
      name: json['name'],
      description: json['description'],
      criteria: Map<String, dynamic>.from(json['criteria'] ?? {}),
      customerIds: List<String>.from(json['customerIds'] ?? []),
      customerCount: json['customerCount'] ?? 0,
      type: json['type'] ?? 'dynamic',
      isActive: json['isActive'] ?? true,
      color: json['color'] ?? '#2196F3',
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'description': description,
      'criteria': criteria,
      'customerIds': customerIds,
      'customerCount': customerCount,
      'type': type,
      'isActive': isActive,
      'color': color,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CustomerSegment copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? description,
    Map<String, dynamic>? criteria,
    List<String>? customerIds,
    int? customerCount,
    String? type,
    bool? isActive,
    String? color,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerSegment(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      customerIds: customerIds ?? this.customerIds,
      customerCount: customerCount ?? this.customerCount,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CustomerNote {
  final String id;
  final String customerId;
  final String merchantId;
  final String title;
  final String content;
  final String type; // 'general', 'reminder', 'important', 'private'
  final String? priority; // 'low', 'medium', 'high', 'urgent'
  final bool isPrivate;
  final DateTime? reminderDate;
  final bool isCompleted;
  final List<String> tags;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerNote({
    required this.id,
    required this.customerId,
    required this.merchantId,
    required this.title,
    required this.content,
    this.type = 'general',
    this.priority,
    this.isPrivate = false,
    this.reminderDate,
    this.isCompleted = false,
    this.tags = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerNote.fromJson(Map<String, dynamic> json) {
    return CustomerNote(
      id: json['id'],
      customerId: json['customerId'],
      merchantId: json['merchantId'],
      title: json['title'],
      content: json['content'],
      type: json['type'] ?? 'general',
      priority: json['priority'],
      isPrivate: json['isPrivate'] ?? false,
      reminderDate: json['reminderDate'] != null ? DateTime.parse(json['reminderDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'merchantId': merchantId,
      'title': title,
      'content': content,
      'type': type,
      'priority': priority,
      'isPrivate': isPrivate,
      'reminderDate': reminderDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'tags': tags,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CustomerNote copyWith({
    String? id,
    String? customerId,
    String? merchantId,
    String? title,
    String? content,
    String? type,
    String? priority,
    bool? isPrivate,
    DateTime? reminderDate,
    bool? isCompleted,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerNote(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      merchantId: merchantId ?? this.merchantId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isPrivate: isPrivate ?? this.isPrivate,
      reminderDate: reminderDate ?? this.reminderDate,
      isCompleted: isCompleted ?? this.isCompleted,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasReminder => reminderDate != null;
  bool get isReminderDue => reminderDate != null && reminderDate!.isBefore(DateTime.now());
  
  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return '#F44336'; // Red
      case 'high':
        return '#FF5722'; // Deep Orange
      case 'medium':
        return '#FF9800'; // Orange
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String get typeIcon {
    switch (type) {
      case 'reminder':
        return 'alarm';
      case 'important':
        return 'star';
      case 'private':
        return 'lock';
      default:
        return 'note';
    }
  }
}