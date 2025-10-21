import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';
import '../models/transaction_model.dart';
import '../widgets/notification_banner.dart';

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
  bool _showBanner = false;
  String _bannerMessage = '';
  NotificationType _bannerType = NotificationType.info;
  bool _usingLocalSimulation = false;
  bool _reverifyInProgress = false;

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
        if (!snap.exists) {
          // If the document isn't present yet, start polling fallback so
          // we can pick up a later-created transaction. In debug builds
          // also start a local simulation if polling/reporting can't find it.
          _startPolling();
          return;
        }
        final data = snap.data();
        if (data == null) return;
        final newTx = TransactionModel.fromJson({ 'id': snap.id, ...data });
        final oldStatus = _current?.status;
        // Received real data from Firestore — clear any previous errors
        // and cancel polling/local simulation so we only show live state.
        setState(() {
          _error = '';
          _current = newTx;
          _usingLocalSimulation = false;
        });
        // If status changed, show a brief banner
        if (oldStatus != null && oldStatus != newTx.status) {
          _bannerMessage = 'Status changed: ${newTx.status}';
          _bannerType = newTx.status.toLowerCase() == 'confirmed' || newTx.status.toLowerCase() == 'completed' ? NotificationType.success : NotificationType.warning;
          setState(() => _showBanner = true);
          // hide after 3s
          Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _showBanner = false); });
        }
      }, onError: (e) {
        setState(() {
          _error = 'Firestore listen error: $e';
        });
        // Listener errored — fall back to polling and in debug try local demo
        _startPolling();
        if (kDebugMode) {
          _startLocalSimulation();
        }
      });
    } catch (e) {
      // If Firestore isn't wired in this app, fallback to periodic polling
      debugPrint('Firestore not available, falling back to polling: $e');
      _startPolling();
    }
  }

  void _startPolling() {
    if (_usingLocalSimulation) return; // don't poll when using local simulated data
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final tx = await _paymentService.getTransaction(widget.transactionId);
        // Got a response from backend — clear any error state and stop
        // local simulation if one was running.
        setState(() {
          _error = '';
          _current = tx;
          _usingLocalSimulation = false;
        });
      } catch (err) {
        // Only surface backend errors if we don't already have a displayed
        // transaction. This prevents a transient 'Transaction not found'
        // from overwriting a simulated or live transaction view.
        if (_current == null) {
          setState(() => _error = err.toString());
        } else {
          debugPrint('Polling error ignored because _current exists: $err');
        }
        // If transaction not found from backend and we're in debug, start a
        // local simulated status progression so the demo still shows changes.
        if (kDebugMode && _current == null && err.toString().toLowerCase().contains('transaction not found')) {
          _startLocalSimulation();
        }
      }
    });
  }

  // Debug-only local simulation for demo: progress through statuses so the
  // UI can show transitions even if emulator/backend are unreachable.
  void _startLocalSimulation() {
    if (!kDebugMode) return;
    if (_current != null) return; // already have a value
    _usingLocalSimulation = true;
    // Cancel any existing polling so it doesn't race and repopulate _error
    // while the local simulation is running.
    _pollTimer?.cancel();
    // Clear any stale error message so the UI doesn't show 'Transaction not found'
    // while the local simulation runs.
    setState(() {
      _error = '';
    });

    final fake = TransactionModel(
      id: widget.transactionId,
      txHash: widget.transactionId,
      fromAddress: 'simulated-sender',
      toAddress: 'simulated-address-1',
      amountCrypto: 0.1,
      cryptoCurrency: 'ETH',
      network: 'sepolia',
      status: 'pending',
      confirmedAt: null,
      observedAt: null,
      blockNumber: null,
      confirmations: 0,
      requiredConfirmations: 1,
      metadata: null,
    );

    setState(() {
      _current = fake;
      _bannerMessage = 'Status changed: pending';
      _bannerType = NotificationType.info;
      _showBanner = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _current = TransactionModel(
          id: fake.id,
          txHash: fake.txHash,
          fromAddress: fake.fromAddress,
          toAddress: fake.toAddress,
          amountCrypto: fake.amountCrypto,
          cryptoCurrency: fake.cryptoCurrency,
          network: fake.network,
          status: 'confirmed',
          confirmedAt: DateTime.now().toIso8601String(),
          observedAt: fake.observedAt,
          blockNumber: 123456,
          confirmations: 1,
          requiredConfirmations: fake.requiredConfirmations,
          metadata: fake.metadata,
        );
        _bannerMessage = 'Status changed: confirmed';
        _bannerType = NotificationType.success;
        _showBanner = true;
      });
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _current = TransactionModel(
          id: fake.id,
          txHash: fake.txHash,
          fromAddress: fake.fromAddress,
          toAddress: fake.toAddress,
          amountCrypto: fake.amountCrypto,
          cryptoCurrency: fake.cryptoCurrency,
          network: fake.network,
          status: 'completed',
          confirmedAt: DateTime.now().toIso8601String(),
          observedAt: fake.observedAt,
          blockNumber: 123456,
          confirmations: 1,
          requiredConfirmations: fake.requiredConfirmations,
          metadata: fake.metadata,
        );
        _bannerMessage = 'Status changed: completed';
        _bannerType = NotificationType.success;
        _showBanner = true;
        // Local simulation finished — stop suppressing polling so real backend
        // checks can resume if available. Restart polling to pick up any
        // real backend updates, but avoid overwriting current UI with a
        // transient 'not found' error.
        _usingLocalSimulation = false;
        // start polling again to pick up backend state (if needed)
        _startPolling();
      });
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
                onPressed: _usingLocalSimulation ? null : () async {
                  try {
                    final tx = await _paymentService.getTransaction(widget.transactionId);
                    setState(() {
                      _error = '';
                      _current = tx;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshed')));
                  } catch (e) {
                    // If we're running a local simulation, prefer not to spam the
                    // user with backend errors — show a gentle message instead.
                    final msg = _usingLocalSimulation ? 'Refresh disabled during local simulation' : 'Refresh failed: $e';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBody(),
          ),
          if (_showBanner)
            Positioned(top: 0, left: 0, right: 0, child: NotificationBanner(message: _bannerMessage, type: _bannerType, onClose: () { setState(() => _showBanner = false); })),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                Text('Status', style: Theme.of(context).textTheme.titleLarge),
            _buildStatusChip(tx.status),
          ],
        ),
        const SizedBox(height: 12),
            Text('Transaction', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        SelectableText('txHash: ${tx.txHash}'),
        SelectableText('network: ${tx.network}'),
        SelectableText('amount: ${tx.amountCrypto} ${tx.cryptoCurrency}'),
        const SizedBox(height: 12),
            Text('Details', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('from: ${tx.fromAddress}'),
        Text('to: ${tx.toAddress}'),
        if (tx.blockNumber != null) Text('block: ${tx.blockNumber}'),
        if (tx.confirmations != null) Text('confirmations: ${tx.confirmations}/${tx.requiredConfirmations ?? 0}'),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Force re-verify (admin)'),
          onPressed: _reverifyInProgress ? null : () async {
            setState(() { _reverifyInProgress = true; });
            final snack = ScaffoldMessenger.of(context);
            snack.showSnackBar(const SnackBar(content: Text('Reverify requested...')));
            try {
              final res = await _paymentService.reverifyTransaction(tx.txHash, network: tx.network, tokenAddress: tx.metadata?['tokenAddress']);
              snack.hideCurrentSnackBar();
              // Try to present a human-friendly result if available
              String msg = 'Reverify succeeded';
              if (res.containsKey('message')) msg = res['message'].toString();
              else if (res.containsKey('result')) msg = res['result'].toString();
              else if (res.containsKey('success') && res['success'] == true) msg = 'Reverify succeeded';
              snack.showSnackBar(SnackBar(content: Text(msg)));
            } catch (e) {
              snack.hideCurrentSnackBar();
              snack.showSnackBar(SnackBar(content: Text('Reverify failed: $e')));
            } finally {
              if (mounted) setState(() { _reverifyInProgress = false; });
            }
          },
        ),
        const SizedBox(height: 8),
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
                child: Text('Debug mode: Firestore listener + polling fallback enabled', style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
