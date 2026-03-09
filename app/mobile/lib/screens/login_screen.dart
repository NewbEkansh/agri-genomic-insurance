import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// Steps mirror the backend flow:
// phone → otp → (if new) register → home
enum _Step { phone, otp, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Step _step = _Step.phone;
  bool _loading = false;
  String? _error;
  String _jwtToken = '';

  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  // Register fields
  final _nameCtrl = TextEditingController();
  final _latCtrl  = TextEditingController();
  final _lonCtrl  = TextEditingController();
  final _areaCtrl = TextEditingController();
  String _crop     = 'rice';
  String _language = 'hindi';

  final _api = ApiService();

  @override
  void dispose() {
    _phoneCtrl.dispose(); _otpCtrl.dispose(); _nameCtrl.dispose();
    _latCtrl.dispose(); _lonCtrl.dispose(); _areaCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: POST /auth/send-otp ──────────────────────────────────────────
  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _api.sendOtp(phone);
      setState(() { _step = _Step.otp; });
    } catch (_) {
      setState(() { _error = 'Could not send OTP. Check the number and try again.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Step 2: POST /auth/verify-otp ────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.verifyOtp(_phoneCtrl.text.trim(), otp);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', res['token']);
      await prefs.setString('farmer_id', res['farmer_id']);
      await prefs.setString('farmer_phone', _phoneCtrl.text.trim());
      _jwtToken = res['token'];
      if (res['is_new_farmer'] == true) {
        setState(() { _step = _Step.register; });
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (_) {
      setState(() { _error = 'Invalid OTP. Please try again.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  // ── Step 3: POST /farmers/register ───────────────────────────────────────
  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.registerFarmerFull(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cropType: _crop,
        farmLat: double.tryParse(_latCtrl.text) ?? 0.0,
        farmLon: double.tryParse(_lonCtrl.text) ?? 0.0,
        farmAreaHectares: double.tryParse(_areaCtrl.text) ?? 1.0,
        language: _language,
        token: _jwtToken,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('farmer_id', res['farmer_id'] ?? '');
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      setState(() { _error = 'Registration failed. Please try again.'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C08),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logo(),
              const SizedBox(height: 48),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.phone:   return _phoneStep();
      case _Step.otp:     return _otpStep();
      case _Step.register: return _registerStep();
    }
  }

  // ── Phone step ────────────────────────────────────────────────────────────
  Widget _phoneStep() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Get started', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        const Text("Enter your phone number — we'll send a one-time password.",
          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 32),
        _label('Phone Number'),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 15, color: Color(0xFFE5E7EB), fontFamily: 'monospace'),
          decoration: _inputDeco('+91 98765 43210',
            prefix: const Icon(Icons.phone, size: 16, color: Color(0xFF6B7280))),
          onSubmitted: (_) => _sendOtp(),
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorBox(),
        _primaryBtn(_loading ? 'Sending OTP…' : 'Send OTP', _loading ? null : _sendOtp),
        const SizedBox(height: 16),
        const Center(
          child: Text('New farmers are registered automatically after OTP verification.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontFamily: 'monospace')),
        ),
      ],
    );
  }

  // ── OTP step ──────────────────────────────────────────────────────────────
  Widget _otpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(() => setState(() { _step = _Step.phone; _error = null; _otpCtrl.clear(); })),
        const SizedBox(height: 16),
        const Text('Enter OTP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        RichText(text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          children: [
            const TextSpan(text: '6-digit code sent to '),
            TextSpan(text: _phoneCtrl.text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        )),
        const SizedBox(height: 32),
        _label('One-Time Password'),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
            color: Color(0xFF4ADE80), letterSpacing: 12, fontFamily: 'monospace'),
          decoration: _inputDeco('• • • • • •').copyWith(counterText: ''),
          onChanged: (v) { if (v.length == 6) _verifyOtp(); },
        ),
        const SizedBox(height: 24),
        if (_error != null) _errorBox(),
        _primaryBtn(_loading ? 'Verifying…' : 'Verify & Continue', _loading ? null : _verifyOtp),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _sendOtp,
            child: const Text("Didn't receive it? Resend OTP",
              style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontFamily: 'monospace')),
          ),
        ),
      ],
    );
  }

  // ── Register step ─────────────────────────────────────────────────────────
  Widget _registerStep() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set up your farm',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('First time? Takes 30 seconds.',
          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 32),

        _label('Full Name'),
        TextField(controller: _nameCtrl, style: _monoStyle(),
          decoration: _inputDeco('Rajan Kumar')),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Crop Type'),
            _dropdownField(_crop, ['rice','wheat','maize','cotton','soybean'],
              (v) => setState(() => _crop = v!)),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Language'),
            _dropdownField(_language, ['hindi','telugu','tamil','marathi','english'],
              (v) => setState(() => _language = v!)),
          ])),
        ]),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Latitude'),
            TextField(controller: _latCtrl, style: _monoStyle(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('28.6139')),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Longitude'),
            TextField(controller: _lonCtrl, style: _monoStyle(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco('77.2090')),
          ])),
        ]),
        const SizedBox(height: 16),

        _label('Farm Area (hectares)'),
        TextField(controller: _areaCtrl, style: _monoStyle(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDeco('3.5')),
        const SizedBox(height: 24),

        if (_error != null) _errorBox(),
        _primaryBtn(_loading ? 'Setting up…' : 'Complete Registration', _loading ? null : _register),
        const SizedBox(height: 12),
        const Center(
          child: Text('Your wallet is created automatically — no MetaMask needed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontFamily: 'monospace')),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _logo() {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: const Color(0xFF14532D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF16A34A))),
        child: const Icon(Icons.eco, color: Color(0xFF4ADE80), size: 20),
      ),
      const SizedBox(width: 12),
      RichText(text: const TextSpan(
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: 'Yield', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'Shield', style: TextStyle(color: Color(0xFF4ADE80))),
        ],
      )),
    ]);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280),
        fontFamily: 'monospace', letterSpacing: 1.0)),
  );

  Widget _backButton(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.chevron_left, color: Color(0xFF6B7280), size: 18),
      Text('Back', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontFamily: 'monospace')),
    ]),
  );

  TextStyle _monoStyle() => const TextStyle(fontSize: 14, color: Color(0xFFE5E7EB), fontFamily: 'monospace');

  InputDecoration _inputDeco(String hint, { Widget? prefix }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF4B5563), fontFamily: 'monospace'),
    prefixIcon: prefix,
    filled: true,
    fillColor: const Color(0xFF1A1F0E),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF242B12))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF242B12))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF16A34A))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _dropdownField(String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1A1F0E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF242B12))),
      child: DropdownButton<String>(
        value: value, onChanged: onChanged, isExpanded: true,
        dropdownColor: const Color(0xFF1A1F0E), underline: const SizedBox(),
        style: const TextStyle(fontSize: 14, color: Color(0xFFE5E7EB), fontFamily: 'monospace'),
        items: options.map((o) => DropdownMenuItem(value: o,
          child: Text(o[0].toUpperCase() + o.substring(1)))).toList(),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ADE80),
          foregroundColor: const Color(0xFF0A0C08),
          disabledBackgroundColor: const Color(0xFF4ADE80).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: onTap == null
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Color(0xFF0A0C08), strokeWidth: 2))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
      ),
    );
  }

  Widget _errorBox() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0x1AEF4444),
      border: Border.all(color: const Color(0x4DEF4444)),
      borderRadius: BorderRadius.circular(8)),
    child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFF87171), fontFamily: 'monospace')),
  );
}