import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String mentorId;
  final int durationMinutes;
  final double price;

  const CheckoutScreen({
    super.key,
    required this.mentorId,
    required this.durationMinutes,
    required this.price,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _processing = false;
  String? _error;

  double get _platformFee => 4.0;
  double get _mentorPayout => double.parse((widget.price - _platformFee).toStringAsFixed(2));

  Future<void> _confirmPayment() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final result = await ApiService.checkout(
        menteeId: user.id,
        mentorId: widget.mentorId,
        durationMinutes: widget.durationMinutes,
        price: widget.price,
      );
      await auth.refreshUser();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ReceiptDialog(receipt: result['receipt'] ?? {}),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Escrow Hold')),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Session Order Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Session duration', '${widget.durationMinutes} minutes'),
                    const SizedBox(height: 10),
                    _row('Gross session fee', '\$${widget.price.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    _row('Platform protection fee (escrow)', '\$${_platformFee.toStringAsFixed(2)}',
                        color: AppColors.textSecondary),
                    const Divider(height: 24, color: AppColors.border),
                    _row('Mentor net payout (held in escrow)', '\$${_mentorPayout.toStringAsFixed(2)}',
                        color: AppColors.mint, bold: true),
                    const Divider(height: 24, color: AppColors.border),
                    _row('Total charged today', '\$${widget.price.toStringAsFixed(2)}', bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Sandbox Escrow Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const _DemoCardForm(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _processing ? null : _confirmPayment,
              child: _processing
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Confirm Escrow Payment · \$${widget.price.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Funds are securely held in escrow until the session is completed and reviewed.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TextStyle(color: color ?? AppColors.textPrimary))),
        Text(value,
            style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _DemoCardForm extends StatelessWidget {
  const _DemoCardForm();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _PrefilledField(label: 'Sandbox Card Number', value: '4242 •••• •••• 4242'),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PrefilledField(label: 'Expiry', value: '12/29')),
                SizedBox(width: 12),
                Expanded(child: _PrefilledField(label: 'CVC', value: '123')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefilledField extends StatelessWidget {
  final String label;
  final String value;
  const _PrefilledField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> receipt;
  const _ReceiptDialog({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(children: const [
        Icon(Icons.check_circle, color: AppColors.mint),
        SizedBox(width: 8),
        Text('Payment Confirmed'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('Transaction ID', '${receipt['transactionId'] ?? '-'}'),
          _line('Gross amount', '\$${(receipt['grossAmount'] ?? 0).toStringAsFixed(2)}'),
          _line('Platform fee', '\$${(receipt['platformProtectionFee'] ?? 4.0).toStringAsFixed(2)}'),
          _line('Mentor payout (escrow)', '\$${(receipt['mentorNetPayout'] ?? 16.0).toStringAsFixed(2)}'),
          _line('Escrow status', '${receipt['escrowStatus'] ?? 'held_in_escrow'}'),
          _line('Remaining wallet', '\$${(receipt['remainingWallet'] ?? 0).toStringAsFixed(2)}'),
        ],
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go to Sessions')),
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
