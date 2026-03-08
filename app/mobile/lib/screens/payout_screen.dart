import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yieldshield/l10n/app_localizations.dart';
import '../models/farmer_model.dart';
import '../services/api_service.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final _api = ApiService();
  List<PayoutRecord> _payouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final payouts = await _api.getPayoutHistory('FARM_001');
    setState(() {
      _payouts = payouts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalEth = _payouts.fold(0.0, (sum, p) => sum + p.amountEth);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text(l10n.payoutHistory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2E7D32),
              child: Column(
                children: [
                  _buildSummaryBanner(totalEth),
                  Expanded(
                    child: _payouts.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _payouts.length,
                            itemBuilder: (ctx, i) => _PayoutCard(payout: _payouts[i], index: i),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryBanner(double totalEth) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: l10n.totalPayouts, value: '${_payouts.length}', icon: Icons.receipt_long),
          Container(width: 1, height: 40, color: Colors.white24),
          _SummaryItem(label: l10n.totalEthReceived, value: '${totalEth.toStringAsFixed(2)} ETH', icon: Icons.account_balance_wallet_outlined),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.grey[400], size: 70),
          const SizedBox(height: 16),
          Text(l10n.noPayoutsYet, style: const TextStyle(fontSize: 18, color: Color(0xFF666666))),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final PayoutRecord payout;
  final int index;

  const _PayoutCard({required this.payout, required this.index});

  Future<void> _openEtherscan(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final url = Uri.parse('https://sepolia.etherscan.io/tx/${payout.txHash}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenEtherscan), backgroundColor: const Color(0xFFEF5350)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFullPayout = payout.payoutPercent == 100;
    final color = isFullPayout ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final shortHash = '${payout.txHash.substring(0, 10)}...${payout.txHash.substring(payout.txHash.length - 6)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(payout.diseaseType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    isFullPayout ? l10n.fullPayout : 'PARTIAL (${payout.payoutPercent}%)',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.amount, style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                    Text('${payout.amountEth} ETH',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A2E))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.date, style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                    Text(_formatDate(payout.timestamp), style: const TextStyle(color: Color(0xFF444444), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.status, style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: payout.status == 'confirmed'
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        payout.status.toUpperCase(),
                        style: TextStyle(
                          color: payout.status == 'confirmed' ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.link, color: Color(0xFF2196F3), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(shortHash,
                          style: const TextStyle(color: Color(0xFF2196F3), fontSize: 13, fontFamily: 'monospace')),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: payout.txHash));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.txHashCopied), duration: const Duration(seconds: 2), backgroundColor: const Color(0xFF2E7D32)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.copy, color: Color(0xFF999999), size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openEtherscan(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.open_in_new, color: Color(0xFF1565C0), size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100), duration: 400.ms).slideX(begin: 0.05);
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}