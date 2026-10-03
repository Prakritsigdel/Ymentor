import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';

class CheckoutScreen extends StatefulWidget {
  final String mentorId;
  final int durationMinutes;
  final double price;
  final double monthlyPrice;
  final String planType;
  final DateTime? scheduledTime;
  final double mentorHourlyRate;
  final AppUser? mentor;

  const CheckoutScreen({
    super.key,
    required this.mentorId,
    required this.durationMinutes,
    required this.price,
    this.monthlyPrice = 0,
    this.planType = 'hourly',
    this.scheduledTime,
    this.mentorHourlyRate = 0,
    this.mentor,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _processing = false;
  late bool _monthlyPlan;
  double? _calculatedFee;
  double? _fetchedMentorRate;
  double? _fetchedMonthlyRate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _monthlyPlan = widget.planType == 'monthly';
    if ((widget.mentorHourlyRate < 500 && (widget.mentor?.hourlyRate ?? 0) < 500) ||
        widget.price < 500) {
      _fetchMentorData();
    } else {
      _loadFee();
    }
  }

  Future<void> _fetchMentorData() async {
    try {
      final res = await ApiService.getMentorProfile(widget.mentorId);
      if (res['mentor'] is Map && mounted) {
        final m = AppUser.fromJson(res['mentor'] as Map<String, dynamic>);
        setState(() {
          if (m.hourlyRate >= 500) {
            _fetchedMentorRate = m.hourlyRate;
          }
          final mRate = (m.mentorProfile['monthlyRate'] as num?)?.toDouble();
          if (mRate != null && mRate >= 5000) {
            _fetchedMonthlyRate = mRate;
          }
        });
      }
    } catch (_) {
      // Fallback to widget provided data
    } finally {
      if (mounted) _loadFee();
    }
  }

  double get _selectedHours =>
      (widget.durationMinutes > 0 ? widget.durationMinutes : 60) / 60.0;

  double get _hourlyRate {
    if (widget.mentor != null && widget.mentor!.hourlyRate >= 500) {
      return widget.mentor!.hourlyRate;
    }
    if (widget.mentorHourlyRate >= 500) {
      return widget.mentorHourlyRate;
    }
    if (_fetchedMentorRate != null && _fetchedMentorRate! >= 500) {
      return _fetchedMentorRate!;
    }
    if (widget.price >= 500) {
      return widget.price / _selectedHours;
    }
    return 1000.0;
  }

  double get _monthlyRate {
    if (widget.monthlyPrice >= 5000) return widget.monthlyPrice;
    if (widget.mentor != null) {
      final mRate = (widget.mentor!.mentorProfile['monthlyRate'] as num?)?.toDouble();
      if (mRate != null && mRate >= 5000) return mRate;
    }
    if (_fetchedMonthlyRate != null && _fetchedMonthlyRate! >= 5000) {
      return _fetchedMonthlyRate!;
    }
    return 10000.0;
  }

  double get _basePrice {
    if (_monthlyPlan) {
      return _monthlyRate;
    }
    return _hourlyRate * _selectedHours;
  }

  double get _platformFee =>
      _calculatedFee ?? (_basePrice * 0.20).roundToDouble();

  double get _mentorNetPayout =>
      (_basePrice - _platformFee).roundToDouble();

  double get _totalCharged => _basePrice;

  Future<void> _loadFee() async {
    final amount = _basePrice;
    try {
      final result = await ApiService.getPlatformFee(amount);
      if (mounted) {
        setState(() => _calculatedFee = (result['fee'] as num).toDouble());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Unable to verify the platform fee. Try again before checkout.');
      }
    }
  }

  Future<void> _confirmPayment() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final result = _monthlyPlan
          ? await ApiService.checkoutMonthly(widget.mentorId)
          : await ApiService.checkout(
              menteeId: user.id,
              mentorId: widget.mentorId,
              durationMinutes: widget.durationMinutes > 0 ? widget.durationMinutes : 60,
              durationInHours: _selectedHours,
              basePrice: _basePrice,
              price: _basePrice,
              scheduledTime:
                  widget.scheduledTime ?? DateTime.now().add(const Duration(days: 1)),
            );
      await auth.refreshUser();
      if (!mounted) return;
      final receipt = _monthlyPlan
          ? {
              'transactionId': result['booking']?['_id'] ?? '-',
              'grossAmount': _basePrice,
              'platformProtectionFee': _platformFee,
              'mentorNetPayout': _mentorNetPayout,
              'escrowStatus': 'held_in_escrow',
              'remainingWallet': auth.user?.walletBalance ?? 0,
            }
          : result['receipt'] ?? {};
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ReceiptDialog(receipt: receipt),
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
            SegmentedButton<bool>(
              segments: [
                const ButtonSegment(
                    value: false, label: Text('Hourly session')),
                if (widget.monthlyPrice > 0)
                  const ButtonSegment(value: true, label: Text('Monthly plan')),
              ],
              selected: {_monthlyPlan},
              onSelectionChanged: (selection) {
                setState(() {
                  _monthlyPlan = selection.first;
                  _calculatedFee = null;
                });
                _loadFee();
              },
            ),
            const SizedBox(height: 16),
            const Text('Session Order Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (!_monthlyPlan) ...[
                      _row('Session duration',
                          '${_selectedHours.toStringAsFixed(_selectedHours.truncateToDouble() == _selectedHours ? 0 : 1)} hour(s)'),
                      _row(
                        'Rate',
                        '${CurrencyUtils.formatNPR(_hourlyRate)} / hr × ${_selectedHours.toStringAsFixed(_selectedHours.truncateToDouble() == _selectedHours ? 0 : 1)} hr',
                        color: AppColors.textSecondary,
                      ),
                    ],
                    if (_monthlyPlan) _row('Plan period', '30 days'),
                    const SizedBox(height: 10),
                    _row('Base price', CurrencyUtils.formatNPR(_basePrice)),
                    const SizedBox(height: 10),
                    _row('Platform protection fee (escrow)',
                        CurrencyUtils.formatNPR(_platformFee),
                        color: AppColors.textSecondary),
                    const Divider(height: 24, color: AppColors.border),
                    _row('Mentor net payout (held in escrow)',
                        CurrencyUtils.formatNPR(_mentorNetPayout),
                        color: AppColors.mint, bold: true),
                    const Divider(height: 24, color: AppColors.border),
                    _row('Total charged', CurrencyUtils.formatNPR(_totalCharged),
                        bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
                _monthlyPlan
                    ? 'Monthly mentorship includes'
                    : 'Bank-Grade Escrow Protection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _monthlyPlan
                ? const _MonthlyPlanDetails()
                : const _PaymentSecurityCard(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ],
            const SizedBox(height: 24),
            if (_error != null)
              TextButton(
                  onPressed: _loadFee,
                  child: const Text('Recheck platform fee')),
            ElevatedButton(
              onPressed: _processing || _calculatedFee == null
                  ? null
                  : _confirmPayment,
              child: _processing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_monthlyPlan
                      ? 'Start Monthly Plan · ${CurrencyUtils.formatNPR(_totalCharged)}'
                      : 'Confirm Escrow Payment · ${CurrencyUtils.formatNPR(_totalCharged)}'),
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
        Expanded(
            child: Text(label,
                style: TextStyle(color: color ?? AppColors.textPrimary))),
        Text(value,
            style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _MonthlyPlanDetails extends StatelessWidget {
  const _MonthlyPlanDetails();

  @override
  Widget build(BuildContext context) => const _PaymentSecurityCard(
        message:
            '30 days of dedicated mentorship, weekly live calls, async messaging, and a shared workspace.',
      );
}

class _PaymentSecurityCard extends StatelessWidget {
  final String message;
  const _PaymentSecurityCard({
    this.message =
        'Your payment is held securely until the session is complete.',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.mint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          _line('Gross amount',
              CurrencyUtils.formatNPR((receipt['grossAmount'] ?? 0) as num)),
          _line(
              'Platform fee',
              CurrencyUtils.formatNPR(
                  (receipt['platformProtectionFee'] ?? 0) as num)),
          _line(
              'Mentor payout (escrow)',
              CurrencyUtils.formatNPR(
                  (receipt['mentorNetPayout'] ?? 0) as num)),
          _line('Escrow status',
              '${receipt['escrowStatus'] ?? 'held_in_escrow'}'),
          _line(
              'Remaining wallet',
              CurrencyUtils.formatNPR(
                  (receipt['remainingWallet'] ?? 0) as num)),
        ],
      ),
      actions: [
        ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go to Sessions')),
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
