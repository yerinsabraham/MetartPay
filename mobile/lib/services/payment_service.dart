import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class PaymentService {
  final String baseUrl;
  final Duration timeout;

  PaymentService({required this.baseUrl, this.timeout = const Duration(seconds: 10)});

  // Create a synthetic payment (dev mode)
  Future<String> createPayment(Map<String, dynamic> payload, {String? simulateKey}) async {
    final url = Uri.parse('$baseUrl/payments/simulate-confirm');
    try {
      final headers = { 'Content-Type': 'application/json' };
      if (simulateKey != null) headers['x-dev-simulate-key'] = simulateKey;

      final resp = await http
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['transactionId'] != null) return body['transactionId'] as String;
        throw ApiException('Missing transactionId in response');
      } else if (resp.statusCode == 403) {
        throw ApiException('Forbidden: invalid simulate key');
      } else {
        throw ApiException('Unexpected response: ${resp.statusCode} ${resp.body}');
      }
    } on TimeoutException catch (_) {
      throw ApiException('Request timed out');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unknown error: $e');
    }
  }

  // Get transaction details
  Future<TransactionModel> getTransaction(String id) async {
    final url = Uri.parse('$baseUrl/transactions/$id');
    try {
      final resp = await http.get(url).timeout(timeout);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['transaction'] != null) {
          return TransactionModel.fromJson(body['transaction']);
        }
        throw ApiException('Malformed response');
      } else if (resp.statusCode == 404) {
        throw ApiException('Transaction not found');
      } else {
        throw ApiException('Unexpected response: ${resp.statusCode}');
      }
    } on TimeoutException catch (_) {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unknown error: $e');
    }
  }

  // Admin: re-run verification for txHash
  Future<Map<String, dynamic>> reverifyTransaction(String txHash, {String? network, String? tokenAddress}) async {
    final url = Uri.parse('$baseUrl/admin/reverify/$txHash');
    try {
      final body = <String, dynamic>{};
      if (network != null) body['network'] = network;
      if (tokenAddress != null) body['tokenAddress'] = tokenAddress;

      final resp = await http.post(url, headers: { 'Content-Type': 'application/json' }, body: jsonEncode(body)).timeout(timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        throw ApiException('Unexpected response: ${resp.statusCode} ${resp.body}');
      }
    } on TimeoutException catch (_) {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unknown error: $e');
    }
  }
}
