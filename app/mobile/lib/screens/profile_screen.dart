import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:yieldshield/l10n/app_localizations.dart';
import '../main.dart';
import '../models/farmer_model.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Farmer? _farmer;
  bool _loading = true;

  static const _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'hi', 'label': 'हिंदी'},
    {'code': 'ta', 'label': 'தமிழ்'},
    {'code': 'te', 'label': 'తెలుగు'},
    {'code': 'bn', 'label': 'বাংলা'},
    {'code': 'mr', 'label': 'मराठी'},
    {'code': 'gu', 'label': 'ગુજરાતી'},
    {'code': 'kn', 'label': 'ಕನ್ನಡ'},
    {'code': 'ml', 'label': 'മലയാളം'},
    {'code': 'pa', 'label': 'ਪੰਜਾਬੀ'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final farmer = await _api.getFarmer('FARM_001');
    setState(() {
      _farmer = farmer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildWalletCard(),
                      const SizedBox(height: 16),
                      _buildLanguageCard(),
                      const SizedBox(height: 16),
                      _buildFarmDetails(),
                      const SizedBox(height: 16),
                      _buildInsuranceCard(),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 12),
                Text(
                  _farmer?.name ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  _farmer?.location ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 12),
          Text(l10n.selectLanguage, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1A2E))),
          const Spacer(),
          DropdownButton<String>(
            value: currentLocale,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            items: _languages.map((lang) => DropdownMenuItem(
              value: lang['code'],
              child: Text(lang['label']!),
            )).toList(),
            onChanged: (code) {
              if (code != null) YieldShieldApp.setLocale(context, Locale(code));
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 400.ms);
  }

  Widget _buildWalletCard() {
    final l10n = AppLocalizations.of(context)!;
    final wallet = _farmer?.walletAddress ?? '';
    final shortWallet = wallet.length > 12
        ? '${wallet.substring(0, 8)}...${wallet.substring(wallet.length - 6)}'
        : wallet;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(l10n.walletAddress, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('Sepolia', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(shortWallet,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: wallet));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.walletCopied), backgroundColor: const Color(0xFF2E7D32), duration: const Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.copy, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildFarmDetails() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.farmDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.tag, label: l10n.farmId, value: _farmer?.farmId ?? '-'),
          _DetailRow(icon: Icons.grass, label: l10n.cropHealth, value: _farmer?.cropType ?? '-'),
          _DetailRow(icon: Icons.location_on_outlined, label: l10n.location, value: _farmer?.location ?? '-'),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildInsuranceCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.insurancePolicy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.shield_outlined, label: l10n.insuredAmount, value: '${_farmer?.insuredAmountEth ?? 0} ETH', valueColor: const Color(0xFF2E7D32)),
          _DetailRow(icon: Icons.verified_outlined, label: l10n.contract, value: '0x722b...DA9C', valueColor: const Color(0xFF1565C0)),
          _DetailRow(icon: Icons.bolt_outlined, label: l10n.payoutTrigger, value: l10n.aiTrigger, valueColor: const Color(0xFFE65100)),
          _DetailRow(icon: Icons.account_tree_outlined, label: l10n.network, value: l10n.sepoliaTestnet),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF999999), size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1A1A2E), fontSize: 14)),
        ],
      ),
    );
  }
}