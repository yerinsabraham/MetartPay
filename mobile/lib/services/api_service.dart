import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl =
      'https://metartpay-api-456120304945.us-central1.run.app';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Unknown error occurred',
        statusCode: response.statusCode,
      );
    }
  }

  // Merchant endpoints
  Future<Map<String, dynamic>> createMerchant({
    required String businessName,
    required String bankAccountNumber,
    required String bankName,
    required String bankAccountName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException(message: 'User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/merchants'),
      headers: await _getHeaders(),
      body: json.encode({
        'userId': user.uid,
        'businessName': businessName,
        'bankAccountNumber': bankAccountNumber,
        'bankName': bankName,
        'bankAccountName': bankAccountName,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMerchant(String merchantId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/merchants/$merchantId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<List<dynamic>> getUserMerchants() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw ApiException(message: 'User not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/merchants/user/${user.uid}'),
      headers: await _getHeaders(),
    );

    final data = await _handleResponse(response);
    return data['data'] as List<dynamic>;
  }

  // Invoice endpoints
  Future<Map<String, dynamic>> createInvoice({
    required String merchantId,
    required double amountNaira,
    required String chain,
    required String token,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices'),
      headers: await _getHeaders(),
      body: json.encode({
        'merchantId': merchantId,
        'amountNaira': amountNaira,
        'chain': chain,
        'token': token,
        'metadata': metadata ?? {},
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getInvoice(String invoiceId) async {
    final response = await http.get(Uri.parse('$baseUrl/invoices/$invoiceId'));

    return _handleResponse(response);
  }

  Future<List<dynamic>> getMerchantInvoices(
    String merchantId, {
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/invoices/merchant/$merchantId').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      },
    );

    final response = await http.get(uri, headers: await _getHeaders());

    final data = await _handleResponse(response);
    return data['data'] as List<dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
