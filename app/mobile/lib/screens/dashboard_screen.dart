import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yieldshield/l10n/app_localizations.dart';
import '../models/farmer_model.dart';
import '../services/api_service.dart';
import '../widgets/farm_health_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Farmer? _farmer;
  FarmHealth? _health;
  Prediction? _prediction;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final farmer = await _api.getFarmer('FARM_001');
      final health = await _api.getFarmHealth('FARM_001');
      final prediction = await _api.getLatestPrediction('FARM_001');
      setState(() {
        _farmer = farmer;
        _health = health;
        _prediction = prediction;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF2E7D32),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_prediction != null) _buildAlertBanner(),
                        const SizedBox(height: 16),
                        if (_health != null) FarmHealthWidget(health: _health!),
                        const SizedBox(height: 16),
                        _buildQuickStats(),
                        const SizedBox(height: 16),
                        if (_prediction != null) _buildAIAssessment(),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.shield, color: Colors.white, size: 32),
                            Positioned(
                              bottom: 10,
                              child: Container(
                                width: 16,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.namaste}, ${_farmer?.name.split(' ').first ?? ''}! 🌾',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _farmer?.location ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    final l10n = AppLocalizations.of(context)!;
    final p = _prediction!;
    final isHighRisk = p.confidenceScore >= 0.85;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighRisk ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighRisk ? const Color(0xFFEF5350) : const Color(0xFFFF9800),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHighRisk ? Icons.crisis_alert : Icons.warning_amber_rounded,
            color: isHighRisk ? const Color(0xFFEF5350) : const Color(0xFFFF9800),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHighRisk ? l10n.payoutTriggered : l10n.diseaseDetected,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighRisk ? const Color(0xFFEF5350) : const Color(0xFFE65100),
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${p.diseaseType.replaceAll('_', ' ').toUpperCase()} — ${(p.confidenceScore * 100).toInt()}% ${l10n.confidence}',
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).shake(hz: 2, offset: const Offset(2, 0));
  }

  Widget _buildQuickStats() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _StatCard(label: l10n.crop, value: _farmer?.cropType ?? '-', icon: Icons.grass, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 12),
        _StatCard(label: l10n.insured, value: '${_farmer?.insuredAmountEth ?? 0} ETH', icon: Icons.shield_outlined, color: const Color(0xFF2196F3)),
        const SizedBox(width: 12),
        _StatCard(label: l10n.farmId, value: _farmer?.farmId ?? '-', icon: Icons.tag, color: const Color(0xFF9C27B0)),
      ],
    );
  }

  Widget _buildAIAssessment() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 10),
              Text(l10n.aiAssessment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('AWS Bedrock', style: TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_prediction!.bedrockAssessment, style: const TextStyle(color: Color(0xFF444444), fontSize: 14, height: 1.6)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13), textAlign: TextAlign.center),
            Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}