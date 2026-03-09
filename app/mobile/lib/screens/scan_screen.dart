import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:yieldshield/l10n/app_localizations.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _uploading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final _picker = ImagePicker();

  // ── Image Picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;
      setState(() {
        _image = File(picked.path);
        _result = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not access camera/gallery.');
    }
  }

  // ── Upload & Analyse ───────────────────────────────────────────────────────

  Future<void> _analyse() async {
    if (_image == null) return;
    setState(() {
      _uploading = true;
      _result = null;
      _error = null;
    });

    // ── MOCK MODE: remove this block when backend is live ──────────────────
    const bool mockMode = true;
    if (mockMode) {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _result = {
          'disease_type': 'rice_blast',
          'confidence_score': 0.92,
          'payout_percent': 100,
          'bedrock_assessment':
              'High confidence detection of Magnaporthe oryzae (rice blast). Lesion patterns consistent with acute outbreak. Satellite NDVI confirms 75% vegetation collapse vs. baseline. Full payout approved.',
          'payout_triggered': true,
          'tx_hash': '0x39db3dad642269c41dcca3c0f136b76637dbe18af09d85668755f734a680cbd2',
        };
        _uploading = false;
      });
      return;
    }
    // ── END MOCK ────────────────────────────────────────────────────────────

    try {
      // POST /predictions/score  — multipart image upload
      // NOTE: This endpoint is called by the AI pipeline. If your backend
      // exposes a direct upload endpoint for the app, update the path below.
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/predictions/score'),
      );
      request.fields['farmer_id'] = 'demo-farmer-001';
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        setState(() {
          _result = jsonDecode(res.body);
          _uploading = false;
        });
      } else {
        setState(() {
          _error = 'Server error ${res.statusCode}. Try again.';
          _uploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Upload failed. Check your connection.';
        _uploading = false;
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('Scan Crop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInstructions(),
            const SizedBox(height: 16),
            _buildImageArea(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            if (_uploading) _buildLoadingCard(),
            if (_error != null) _buildErrorCard(),
            if (_result != null) _buildResultCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Take a clear photo of the affected crop leaves for best accuracy.',
              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: () => _showSourcePicker(),
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _image != null
                ? const Color(0xFF2E7D32)
                : const Color(0xFFDDDDDD),
            width: _image != null ? 2 : 1.5,
            style: _image != null ? BorderStyle.solid : BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: _image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(_image!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32), size: 34),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tap to add crop photo',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Camera or Gallery',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_image != null) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _uploading ? null : _analyse,
              icon: _uploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.biotech),
              label: Text(_uploading ? 'Analysing...' : 'Analyse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF2E7D32)),
          const SizedBox(height: 16),
          const Text('AWS Bedrock analysing your crop...', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('This takes 2–5 seconds', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF5350)),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF5350)))),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shake();
  }

  Widget _buildResultCard() {
    final r = _result!;
    final confidence = ((r['confidence_score'] as num) * 100).toInt();
    final isHighRisk = confidence >= 85;
    final payoutTriggered = r['payout_triggered'] == true;
    final riskColor = isHighRisk ? const Color(0xFFEF5350) : const Color(0xFFFF9800);

    return Column(
      children: [
        // Disease Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
              Icon(payoutTriggered ? Icons.verified : Icons.warning_amber_rounded, color: Colors.white, size: 48)
                  .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 10),
              Text(
                (r['disease_type'] as String).replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                payoutTriggered ? '⚡ Payout Triggered Automatically' : '⚠️ Below payout threshold',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

        const SizedBox(height: 12),

        // Confidence + Payout %
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Confidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Confidence Score', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text('$confidence%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: riskColor)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (r['confidence_score'] as num).toDouble(),
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ResultChip(label: 'Payout', value: '${r['payout_percent']}%', color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  _ResultChip(label: 'Threshold', value: '85%', color: const Color(0xFF9C27B0)),
                  const SizedBox(width: 8),
                  _ResultChip(label: 'Oracle', value: 'Auto', color: const Color(0xFF2196F3)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bedrock Assessment
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF1565C0), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('AWS Bedrock Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                r['bedrock_assessment'] as String,
                style: const TextStyle(color: Color(0xFF444444), fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),

        // TX Hash if payout triggered
        if (payoutTriggered && r['tx_hash'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Text('Payout Transaction', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r['tx_hash'] as String,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF444444)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add crop photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.camera_alt, color: Color(0xFF2E7D32))),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.photo_library, color: Color(0xFF1565C0))),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
            Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}