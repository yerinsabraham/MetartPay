import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';
import '../models/transaction_model.dart';

/// PaymentStatusScreen
///
/// Shows transaction status for a given `transactionId`. Prefers Firestore
/// real-time updates (StreamBuilder). If Firestore isn't available in your
/// project, uncomment the polling fallback that uses `PaymentService.getTransaction`.

class PaymentStatusScreen extends StatefulWidget {
  final String transactionId;
  final String baseUrl; // backend base URL for PaymentService

  const PaymentStatusScreen({Key? key, required this.transactionId, required this.baseUrl}) : super(key: key);

  @override
  _PaymentStatusScreenState createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late PaymentService _paymentService;
  StreamSubscription<DocumentSnapshot>? _notifSub;
  TransactionModel? _current;
  String _error = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(baseUrl: widget.baseUrl);
    _startListening();
  }

  void _startListening() {
    try {
      // Firestore real-time subscription
      _notifSub = FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transactionId)
          .snapshots()
          .listen((snap) async {
        if (!snap.exists) return;
        final data = snap.data();
        if (data == null) return;
        setState(() {
          _current = TransactionModel.fromJson({ 'id': snap.id, ...data });
        });
      }, onError: (e) {
        setState(() => _error = 'Firestore listen error: $e');
      });
    } catch (e) {
      // If Firestore isn't wired in this app, fallback to periodic polling
      debugPrint('Firestore not available, falling back to polling: $e');
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final tx = await _paymentService.getTransaction(widget.transactionId);
        setState(() {
          _current = tx;
        });
      } catch (err) {
        setState(() => _error = err.toString());
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatusChip(String status) {
    Color c;
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'verified':
        c = Colors.green;
        break;
      case 'unverified':
        c = Colors.orange;
        break;
      case 'insufficient':
      case 'failed':
        c = Colors.red;
        break;
      default:
        c = Colors.blueGrey;
    }
    return Chip(label: Text(status), backgroundColor: c.withOpacity(0.12), avatar: CircleAvatar(backgroundColor: c, child: Text(status[0].toUpperCase())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        actions: [
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  try {
                    final tx = await _paymentService.getTransaction(widget.transactionId);
                    setState(() => _current = tx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshed')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
                  }
                },
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_current == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tx = _current!;

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Status', style: textTheme.titleMedium),
            _buildStatusChip(tx.status),
          ],
        ),
        const SizedBox(height: 12),
        Text('Transaction', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        SelectableText('txHash: ${tx.txHash}'),
        SelectableText('network: ${tx.network}'),
        SelectableText('amount: ${tx.amountCrypto} ${tx.cryptoCurrency}'),
        const SizedBox(height: 12),
        Text('Details', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        Text('from: ${tx.fromAddress}'),
        Text('to: ${tx.toAddress}'),
        if (tx.blockNumber != null) Text('block: ${tx.blockNumber}'),
        if (tx.confirmations != null) Text('confirmations: ${tx.confirmations}/${tx.requiredConfirmations ?? 0}'),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Force re-verify (admin)'),
          onPressed: () async {
            try {
              final res = await _paymentService.reverifyTransaction(tx.txHash, network: tx.network, tokenAddress: tx.metadata?['tokenAddress']);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reverify: ${res['message'] ?? 'ok'}')));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reverify failed: $e')));
            }
          },
        ),
        const SizedBox(height: 8),
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Debug mode: Firestore listener + polling fallback enabled', style: textTheme.bodySmall),
          ),
      ],
    );
  }
}
