import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/farmer_model.dart';
import '../services/api_service.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final _api = ApiService();
  Prediction? _prediction;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final p = await _api.getLatestPrediction('FARM_001');
    setState(() {
      _prediction = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('Disease Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _prediction == null
              ? _buildNoAlert()
              : _buildAlertDetail(),
    );
  }

  Widget _buildNoAlert() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 80),
          const SizedBox(height: 16),
          const Text(
            'No Active Alerts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          Text(
            'Your crops are healthy!',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertDetail() {
    final p = _prediction!;
    final isHighRisk = p.confidenceScore >= 0.85;
    final riskColor = isHighRisk ? const Color(0xFFEF5350) : const Color(0xFFFF9800);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Risk Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isHighRisk
                    ? [const Color(0xFFB71C1C), const Color(0xFFEF5350)]
                    : [const Color(0xFFE65100), const Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  isHighRisk ? Icons.crisis_alert : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 56,
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(
                  p.diseaseType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isHighRisk ? '⚡ Automatic payout triggered' : '⚠️ Manual review required',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          const SizedBox(height: 16),

          // Confidence Score
          _buildInfoCard(
            title: 'AI Confidence Score',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Confidence', style: TextStyle(color: Color(0xFF666666))),
                    Text(
                      '${(p.confidenceScore * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: p.confidenceScore,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    minHeight: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Threshold: 85%', style: TextStyle(color: Color(0xFF999999), fontSize: 12)),
                    Text(
                      isHighRisk ? 'AUTO-PAYOUT TRIGGERED' : 'BELOW THRESHOLD',
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payout Info
          _buildInfoCard(
            title: 'Payout Details',
            child: Row(
              children: [
                _PayoutStat(
                  label: 'Payout %',
                  value: '${p.payoutPercent}%',
                  color: const Color(0xFF4CAF50),
                ),
                _PayoutStat(
                  label: 'Detected',
                  value: _formatDate(p.detectedAt),
                  color: const Color(0xFF2196F3),
                ),
                _PayoutStat(
                  label: 'Oracle',
                  value: 'Auto',
                  color: const Color(0xFF9C27B0),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bedrock AI Summary
          _buildInfoCard(
            title: '🤖 AWS Bedrock Analysis',
            child: Text(
              p.bedrockAssessment,
              style: const TextStyle(
                color: Color(0xFF444444),
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _PayoutStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PayoutStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
        ],
      ),
    );
  }
}