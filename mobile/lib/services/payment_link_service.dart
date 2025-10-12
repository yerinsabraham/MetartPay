import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      AppLogger.d('Create payment link response: ${response.statusCode}');
      AppLogger.d('Create payment link body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create payment link');
      }
    } catch (e) {
      AppLogger.e('Error creating payment link: $e', error: e);
      throw Exception('Error creating payment link: $e');
    }
  }

  /// Get payment links for a merchant
  /// Returns a map with keys:
  /// - 'links': List<Map<String, dynamic>>
  /// - 'fromCache': bool (true when returned from local cache after failures)
  Future<Map<String, dynamic>> getPaymentLinks(
    String merchantId, {
    String? status,
    int limit = 20,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final token = await user.getIdToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/payment-links/merchant/$merchantId')
        .replace(queryParameters: {
      if (status != null) 'status': status,
      'limit': limit.toString(),
    });

    const int maxAttempts = 3;
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        AppLogger.d('Get payment links response: ${response.statusCode} (attempt $attempt)');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<Map<String, dynamic>> links = List<Map<String, dynamic>>.from(data['paymentLinks'] ?? []);

          // Cache the result for offline/fallback use
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('payment_links_$merchantId', json.encode(links));
          } catch (cacheErr) {
            AppLogger.w('Warning: failed to cache payment links: $cacheErr', error: cacheErr);
          }

          return {'links': links, 'fromCache': false};
        } else {
          // Log body for debugging (may not be JSON)
          AppLogger.d('Get payment links non-200 body: ${response.body}');
          String message;
          try {
            final error = json.decode(response.body);
            message = error['error'] ?? 'Failed to load payment links';
          } catch (_) {
            message = 'Failed to load payment links (status ${response.statusCode}): ${response.body}';
          }
          throw Exception(message);
        }
      } catch (e) {
        AppLogger.e('Attempt $attempt: error loading payment links: $e', error: e);
        if (attempt >= maxAttempts) {
          // Try returning cached links as a fallback
          try {
            final prefs = await SharedPreferences.getInstance();
            final cached = prefs.getString('payment_links_$merchantId');
            if (cached != null) {
              final List<dynamic> cachedList = json.decode(cached);
              final List<Map<String, dynamic>> links = cachedList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
              AppLogger.d('Returning ${links.length} cached payment links after failed attempts');
              return {'links': links, 'fromCache': true};
            }
          } catch (cacheErr) {
            AppLogger.e('Failed to load cached payment links: $cacheErr', error: cacheErr);
          }

          throw Exception('Failed to load payment links after $attempt attempts: $e');
        }
        // exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * (1 << (attempt - 1))));
      }
    }
  }

  /// Get a specific payment link (public endpoint)
  Future<Map<String, dynamic>> getPaymentLink(String linkId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payment-links/$linkId'),
      );

      AppLogger.d('Get payment link response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to load payment link');
      }
    } catch (e) {
      AppLogger.e('Error loading payment link: $e', error: e);
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

      AppLogger.d('Generate QR code response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to generate QR code');
      }
    } catch (e) {
      AppLogger.e('Error generating QR code: $e', error: e);
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

      AppLogger.d('Update payment link response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update payment link');
      }
    } catch (e) {
      AppLogger.e('Error updating payment link: $e', error: e);
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

      AppLogger.d('Delete payment link response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete payment link');
      }
    } catch (e) {
      AppLogger.e('Error deleting payment link: $e', error: e);
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