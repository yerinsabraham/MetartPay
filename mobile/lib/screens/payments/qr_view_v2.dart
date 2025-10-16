import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../services/firebase_service.dart';
import '../../utils/app_logger.dart';
import '../../models/models.dart' as models;
import '../../utils/app_config.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  const CountdownTimer({Key? key, required this.expiresAt}) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.expiresAt.difference(now).isNegative ? Duration.zero : widget.expiresAt.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text('Expires in $minutes:$seconds', style: Theme.of(context).textTheme.bodySmall);
  }
}

class QRViewV2 extends StatefulWidget {
  const QRViewV2({Key? key}) : super(key: key);

  @override
  State<QRViewV2> createState() => _QRViewV2State();
}

class _QRViewV2State extends State<QRViewV2> with SingleTickerProviderStateMixin {
  String _payload = '';
  double _crypto = 0.0;
  String _token = '';
  String? _merchantId;
  String? _paymentId;
  String? _address;
  double? _nairaAmount;
  DateTime? _expiresAt;
  bool _confirmed = false;
  StreamSubscription<List<models.Transaction>>? _txSub;
  final FirebaseService _svc = FirebaseService();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromArgs());
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)).animate(_pulseController);
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });
    _pulseController.forward();
  }

  void _initFromArgs() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    setState(() {
      _payload = args['payload'] ?? '';
      _crypto = (args['crypto'] as num?)?.toDouble() ?? 0.0;
  _token = args['token'] ?? '';
      _merchantId = args['merchantId'];
      _paymentId = args['paymentId'];
      _address = args['address'];
      _nairaAmount = (args['naira'] as num?)?.toDouble();
      if (args['expiresAt'] != null) {
        try {
          _expiresAt = DateTime.parse(args['expiresAt']);
        } catch (_) {
          _expiresAt = null;
        }
      }
    });

    // Subscribe to transactions if merchantId provided
    if (_merchantId != null) {
      _txSub = _svc.watchMerchantTransactions(_merchantId!).listen((txs) {
        for (final t in txs) {
          try {
            // match by paymentId if provided, else match by payload address if possible
            if (_paymentId != null && t.invoiceId == _paymentId && t.status == 'paid') {
              _onConfirmed(t);
              return;
            }

            // If payload is an address-like payload: try to extract address
            if (_payload.startsWith('pay:')) {
              final address = _payload.split(':')[1].split('?').first;
              if (t.toAddress == address && t.status == 'paid') {
                _onConfirmed(t);
                return;
              }
            }
          } catch (_) {}
        }
      });
    }
  }

  void _onConfirmed(models.Transaction t) {
    if (mounted) {
      setState(() => _confirmed = true);
      // Haptic feedback
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment received: ₦${t.amountNaira}')));

      // Try to mark invoice as paid (idempotent on backend)
      _maybeMarkInvoicePaid(t);

      // Auto-dismiss after a short delay (allow merchant to see confirmation)
      const autoDismissSeconds = 3;
      Timer(Duration(seconds: autoDismissSeconds), () {
        if (mounted) Navigator.of(context).maybePop();
      });
      // Save receipt to Firestore for merchant records
      _saveReceiptRecord(t);
    }
  }

  Future<void> _maybeMarkInvoicePaid(models.Transaction t) async {
    try {
      if (t.invoiceId.isNotEmpty) {
        await _svc.updateInvoiceStatus(t.invoiceId, 'paid', txHash: t.txHash);
        AppLogger.d('Marked invoice ${t.invoiceId} as paid (from QRViewV2)');
      }
    } catch (e) {
      AppLogger.e('Failed to update invoice status from QRViewV2: $e', error: e);
    }
  }

  void _shareReceipt(models.Transaction t) async {
    try {
      final receipt = StringBuffer();
      receipt.writeln('MetartPay Receipt');
      receipt.writeln('Merchant: ${_merchantId ?? 'unknown'}');
      receipt.writeln('Invoice: ${t.invoiceId}');
      receipt.writeln('Amount (NGN): ₦${t.amountNaira}');
      receipt.writeln('Amount (${t.cryptoSymbol}): ${t.amountCrypto}');
      receipt.writeln('Chain: ${t.chain}');
      receipt.writeln('TxHash: ${t.txHash ?? '-'}');
      receipt.writeln('Date: ${t.createdAt.toIso8601String()}');
  await SharePlus.instance.share(ShareParams(text: receipt.toString(), subject: 'Payment Receipt'));
    } catch (e) {
      AppLogger.e('Failed to share receipt: $e', error: e);
    }
  }


  Future<void> _saveReceiptRecord(models.Transaction t) async {
    try {
      final docId = 'receipt_${t.id}';
      final payload = {
        'id': docId,
        'merchantId': t.merchantId,
        'transactionId': t.id,
        'invoiceId': t.invoiceId,
        'amountNaira': t.amountNaira,
        'amountCrypto': t.amountCrypto,
        'cryptoSymbol': t.cryptoSymbol,
        'chain': t.chain,
        'txHash': t.txHash,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _svc.saveReceipt(docId, payload);
      AppLogger.d('Saved receipt record $docId');
    } catch (e) {
      AppLogger.e('Failed to save receipt record: $e', error: e);
    }
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final qrSize = (size.width * 0.66).clamp(220.0, 520.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(_paymentId != null ? 'Invoice QR' : 'Quick Receive', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 12),
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (context, child) => Transform.scale(scale: _confirmed ? 1.0 : _pulseAnim.value, child: child),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(data: _payload, size: qrSize),
                                // Overlay small logo at center if asset exists
                                Image.asset('assets/icons/app_logo_qr.png', height: qrSize * 0.18, errorBuilder: (c, e, s) => const SizedBox()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_crypto > 0)
                            Column(
                              children: [
                                Text('${_crypto.toStringAsFixed(6)} $_token', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                if (_nairaAmount != null) const SizedBox(height: 6),
                                if (_nairaAmount != null)
                                  Text('₦${_nairaAmount!.toStringAsFixed(2)}', style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          const SizedBox(height: 8),
                          if (_address != null) Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SelectableText(_address!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Monospace')),
                          ),
                          const SizedBox(height: 8),
                          if (_expiresAt != null) CountdownTimer(expiresAt: _expiresAt!),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Copy address only
                              ElevatedButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: _address ?? _payload)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address copied'))); }, icon: const Icon(Icons.copy), label: const Text('Copy')),
                              const SizedBox(width: 12),
                              // Share payload string
                              ElevatedButton.icon(onPressed: () async { try { await SharePlus.instance.share(ShareParams(text: _payload, subject: 'Payment Request')); } catch (e) { AppLogger.e('Share failed: $e', error: e); } }, icon: const Icon(Icons.share), label: const Text('Share')),
                              const SizedBox(width: 12),
                              // Dev-only: small text button to simulate payment received
                              if (AppConfig.devMockCreate)
                                TextButton(onPressed: () {
                                  setState(() => _confirmed = true);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulated payment received')));
                                }, child: const Text('Simulate'), style: TextButton.styleFrom(foregroundColor: Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_confirmed)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    color: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text('Payment Confirmed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green[900]),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
