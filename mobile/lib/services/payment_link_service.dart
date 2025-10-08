import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class PaymentLinkService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new payment link for a merchant
  Future<Map<String, dynamic>> createPaymentLink({
    required String merchantId,
    required String title,
    String? description,
    required double amount,
    required List<String> networks,
    required List<String> tokens,
    DateTime? expiresAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-links/$merchantId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'amount': amount,
          'networks': networks,
          'tokens': tokens,
          'expiresAt': expiresAt?.toIso8601String(),
        }),
      );

      print('Create payment link response: ${response.statusCode}');
      print('Create payment link body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create payment link');
      }
    } catch (e) {
      print('Error creating payment link: $e');
      throw Exception('Failed to create payment link: $e');
    }
  }

  /// Get payment links for a merchant
  Future<List<Map<String, dynamic>>> getPaymentLinks(
    String merchantId, {
    String? status,
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/payment-links/merchant/$merchantId')
          .replace(queryParameters: {
        if (status != null) 'status': status,
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Get payment links response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['paymentLinks'] ?? []);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to load payment links');
      }
    } catch (e) {
      print('Error loading payment links: $e');
      throw Exception('Failed to load payment links: $e');
    }
  }

  /// Get a specific payment link (public endpoint)
  Future<Map<String, dynamic>> getPaymentLink(String linkId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-links/$linkId'),
      );

      print('Get payment link response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to load payment link');
      }
    } catch (e) {
      print('Error loading payment link: $e');
      throw Exception('Failed to load payment link: $e');
    }
  }

  /// Generate QR code for a payment link
  Future<Map<String, dynamic>> generateQRCode(
    String linkId, {
    required String network,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-links/$linkId/qr')
            .replace(queryParameters: {
          'network': network,
          'token': token,
        }),
      );

      print('Generate QR code response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to generate QR code');
      }
    } catch (e) {
      print('Error generating QR code: $e');
      throw Exception('Failed to generate QR code: $e');
    }
  }

  /// Update payment link status
  Future<void> updatePaymentLinkStatus(
    String linkId, {
    required String status,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-links/$linkId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
        }),
      );

      print('Update payment link response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update payment link');
      }
    } catch (e) {
      print('Error updating payment link: $e');
      throw Exception('Failed to update payment link: $e');
    }
  }

  /// Delete a payment link
  Future<void> deletePaymentLink(String linkId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-links/$linkId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete payment link response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete payment link');
      }
    } catch (e) {
      print('Error deleting payment link: $e');
      throw Exception('Failed to delete payment link: $e');
    }
  }

  /// Get the public payment URL for sharing
  String getPaymentUrl(String linkId, {String? network, String? token}) {
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    final uri = Uri.parse('$baseUrl/pay/$linkId');
    
    if (network != null && token != null) {
      return uri.replace(queryParameters: {
        'network': network,
        'token': token,
      }).toString();
    }
    
    return uri.toString();
  }
}