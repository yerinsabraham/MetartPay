import 'package:flutter/foundation.dart';
import '../services/payment_link_service.dart';
import '../providers/merchant_provider.dart';

class PaymentLinkProvider with ChangeNotifier {
  final PaymentLinkService _paymentLinkService = PaymentLinkService();
  final MerchantProvider _merchantProvider;

  PaymentLinkProvider(this._merchantProvider);

  List<Map<String, dynamic>> _paymentLinks = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get paymentLinks => _paymentLinks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load payment links for current merchant
  Future<void> loadPaymentLinks({String? status}) async {
    try {
      _setLoading(true);
      _setError(null);

      final merchant = _merchantProvider.currentMerchant;
      if (merchant == null) {
        throw Exception('No merchant selected');
      }

      _paymentLinks = await _paymentLinkService.getPaymentLinks(
        merchant.id,
        status: status,
      );
    } catch (e) {
      print('Error loading payment links: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new payment link
  Future<Map<String, dynamic>?> createPaymentLink({
    required String title,
    String? description,
    required double amount,
    required List<String> networks,
    required List<String> tokens,
    DateTime? expiresAt,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final merchant = _merchantProvider.currentMerchant;
      if (merchant == null) {
        throw Exception('No merchant selected');
      }

      final result = await _paymentLinkService.createPaymentLink(
        merchantId: merchant.id,
        title: title,
        description: description,
        amount: amount,
        networks: networks,
        tokens: tokens,
        expiresAt: expiresAt,
      );

      // Refresh the list
      await loadPaymentLinks();

      return result;
    } catch (e) {
      print('Error creating payment link: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate QR code for a payment option
  Future<Map<String, dynamic>?> generateQRCode(
    String linkId, {
    required String network,
    required String token,
  }) async {
    try {
      return await _paymentLinkService.generateQRCode(
        linkId,
        network: network,
        token: token,
      );
    } catch (e) {
      print('Error generating QR code: $e');
      _setError(e.toString());
      return null;
    }
  }

  /// Toggle payment link status (active/inactive)
  Future<void> togglePaymentLinkStatus(String linkId, String currentStatus) async {
    try {
      _setLoading(true);
      _setError(null);

      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      
      await _paymentLinkService.updatePaymentLinkStatus(
        linkId,
        status: newStatus,
      );

      // Update local list
      final index = _paymentLinks.indexWhere((link) => link['id'] == linkId);
      if (index != -1) {
        _paymentLinks[index]['status'] = newStatus;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating payment link status: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a payment link
  Future<void> deletePaymentLink(String linkId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _paymentLinkService.deletePaymentLink(linkId);

      // Remove from local list
      _paymentLinks.removeWhere((link) => link['id'] == linkId);
      notifyListeners();
    } catch (e) {
      print('Error deleting payment link: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Get payment URL for sharing
  String getPaymentUrl(String linkId, {String? network, String? token}) {
    return _paymentLinkService.getPaymentUrl(linkId, network: network, token: token);
  }

  /// Get payment links by status
  List<Map<String, dynamic>> getPaymentLinksByStatus(String status) {
    return _paymentLinks.where((link) => link['status'] == status).toList();
  }

  /// Get active payment links
  List<Map<String, dynamic>> get activePaymentLinks {
    return getPaymentLinksByStatus('active');
  }

  /// Get inactive payment links
  List<Map<String, dynamic>> get inactivePaymentLinks {
    return getPaymentLinksByStatus('inactive');
  }

  /// Get expired payment links
  List<Map<String, dynamic>> get expiredPaymentLinks {
    return getPaymentLinksByStatus('expired');
  }

  /// Get total amount from all active payment links
  double get totalActiveAmount {
    return activePaymentLinks.fold(0.0, (sum, link) => sum + (link['amount'] ?? 0));
  }

  /// Get total payments received
  int get totalPayments {
    return _paymentLinks.fold<int>(0, (sum, link) => sum + (link['totalPayments'] as int? ?? 0));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }
}