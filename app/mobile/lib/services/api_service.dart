import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farmer_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const bool mockMode = true;

  // ── Mock Data ──────────────────────────────────────────────────────────────

  static final Map<String, dynamic> _mockFarmer = {
    'name': 'Ekansh Kumar',
    'farm_id': 'FARM_001',
    'farmer_id': 'demo-farmer-001',
    'wallet_address': '0xC01B11d9F7631025cC4f57f8Bb7aCE8552AdB762',
    'location': 'Punjab, India',
    'insured_amount_eth': 1.0,
    'crop_type': 'Rice',
  };

  static final Map<String, dynamic> _mockHealth = {
    'current_ndvi': 0.18,
    'baseline_ndvi': 0.72,
    'severity': 'critical',
    'soil_data': {'moisture': 21.0, 'temperature': 31.2, 'humidity': 58.0},
    'updated_at': DateTime.now().toIso8601String(),
  };

  static final Map<String, dynamic> _mockPrediction = {
    'disease_type': 'rice_blast',
    'confidence_score': 0.92,
    'bedrock_assessment':
        'High confidence detection of Magnaporthe oryzae (rice blast). Lesion patterns consistent with acute outbreak. Satellite NDVI confirms 75% vegetation collapse vs. baseline. Regional consensus (4/5 neighbouring farms affected) validates genuine disease event. Full payout approved.',
    'payout_percent': 100,
    'detected_at': DateTime.now().toIso8601String(),
  };

  static final List<Map<String, dynamic>> _mockPayouts = [
    {
      'tx_hash': '0x39db3dad642269c41dcca3c0f136b76637dbe18af09d85668755f734a680cbd2',
      'amount_eth': 1.0,
      'payout_percent': 100,
      'disease_type': 'rice_blast',
      'status': 'confirmed',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'tx_hash': '0xabc123def456abc123def456abc123def456abc123def456abc123def456abc1',
      'amount_eth': 0.65,
      'payout_percent': 65,
      'disease_type': 'leaf_blight',
      'status': 'confirmed',
      'timestamp': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    },
  ];

  static final List<Map<String, dynamic>> _mockPolicies = [
    {
      'policy_id': 'POL_001',
      'farm_id': 'FARM_001',
      'insured_amount_eth': 1.0,
      'status': 'active',
      'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    },
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    final res = await http.get(Uri.parse('$baseUrl$path'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : null);
    if (res.statusCode != 200) throw Exception('GET $path failed: ${res.statusCode}');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {String? token}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final res = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('POST $path failed: ${res.statusCode}');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (res.statusCode != 200) throw Exception('PATCH $path failed: ${res.statusCode}');
    return jsonDecode(res.body);
  }

  // ── Health ─────────────────────────────────────────────────────────────────

  Future<bool> checkHealth() async {
    if (mockMode) return true;
    try {
      final res = await http.get(Uri.parse('$baseUrl/health/'));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  /// POST /auth/send-otp
  Future<void> sendOtp(String phone) async {
    if (mockMode) { await Future.delayed(const Duration(milliseconds: 600)); return; }
    final res = await http.post(Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': phone}));
    if (res.statusCode != 200) throw Exception('Failed to send OTP: ${res.statusCode}');
  }

  /// POST /auth/verify-otp → { token, farmer_id, is_new_farmer }
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {'token': 'mock-jwt-token', 'farmer_id': 'demo-farmer-001', 'is_new_farmer': false};
    }
    final res = await http.post(Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': phone, 'otp': otp}));
    if (res.statusCode != 200) throw Exception('Invalid OTP');
    return jsonDecode(res.body);
  }

  // ── Farmers ────────────────────────────────────────────────────────────────

  /// POST /farmers/register (old - with wallet, for backwards compat)
  Future<Farmer> registerFarmer({
    required String name,
    required String walletAddress,
    required String farmId,
    required String location,
    required String cropType,
    required double insuredAmountEth,
  }) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Farmer.fromJson(_mockFarmer);
    }
    final data = await _post('/farmers/register', {
      'name': name, 'wallet_address': walletAddress, 'farm_id': farmId,
      'location': location, 'crop_type': cropType, 'insured_amount_eth': insuredAmountEth,
    });
    return Farmer.fromJson(data);
  }

  /// POST /farmers/register (new - no wallet, backend auto-creates)
  Future<Map<String, dynamic>> registerFarmerFull({
    required String name,
    required String phone,
    required String cropType,
    required double farmLat,
    required double farmLon,
    required double farmAreaHectares,
    required String language,
    required String token,
  }) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {'farmer_id': 'demo-farmer-001'};
    }
    return await _post('/farmers/register', {
      'name': name, 'phone': phone, 'crop_type': cropType,
      'farm_lat': farmLat, 'farm_lon': farmLon,
      'farm_area_hectares': farmAreaHectares, 'language': language,
    }, token: token);
  }

  /// GET /farmers/{farmer_id}
  Future<Farmer> getFarmer(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Farmer.fromJson(_mockFarmer);
    }
    final data = await _get('/farmers/$farmerId');
    return Farmer.fromJson(data);
  }

  /// GET /farmers/{farmer_id}/farm-health
  Future<FarmHealth> getFarmHealth(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return FarmHealth.fromJson(_mockHealth);
    }
    final data = await _get('/farmers/$farmerId/farm-health');
    return FarmHealth.fromJson(data);
  }

  /// GET /predictions/farm/{farm_id}
  Future<Prediction?> getLatestPrediction(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      return Prediction.fromJson(_mockPrediction);
    }
    try {
      final data = await _get('/predictions/farm/$farmerId');
      final predictions = data['predictions'] as List?;
      if (predictions == null || predictions.isEmpty) return null;
      return Prediction.fromJson(predictions.first);
    } catch (_) { return null; }
  }

  /// GET /farmers/{farmer_id}/payouts
  Future<List<PayoutRecord>> getPayoutHistory(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockPayouts.map((p) => PayoutRecord.fromJson(p)).toList();
    }
    final data = await _get('/farmers/$farmerId/payouts');
    final List payouts = data['payouts'] ?? data;
    return payouts.map((p) => PayoutRecord.fromJson(p)).toList();
  }

  /// GET /farmers/{farmer_id}/policies
  Future<List<Map<String, dynamic>>> getFarmerPolicies(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockPolicies;
    }
    final data = await _get('/farmers/$farmerId/policies');
    return List<Map<String, dynamic>>.from(data['policies'] ?? data);
  }

  // ── Policies ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createPolicy({
    required String farmerId,
    required double insuredAmountEth,
    required String cropType,
  }) async {
    if (mockMode) { await Future.delayed(const Duration(milliseconds: 400)); return _mockPolicies.first; }
    return await _post('/policies/create', {'farmer_id': farmerId, 'insured_amount_eth': insuredAmountEth, 'crop_type': cropType});
  }

  Future<Map<String, dynamic>> getPolicy(String policyId) async {
    if (mockMode) { await Future.delayed(const Duration(milliseconds: 300)); return _mockPolicies.first; }
    return await _get('/policies/$policyId');
  }

  Future<bool> cancelPolicy(String policyId) async {
    if (mockMode) { await Future.delayed(const Duration(milliseconds: 300)); return true; }
    try { await _patch('/policies/$policyId/cancel', {}); return true; } catch (_) { return false; }
  }

  // ── Predictions ────────────────────────────────────────────────────────────

  Future<List<Prediction>> getFarmPredictions(String farmId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [Prediction.fromJson(_mockPrediction)];
    }
    final data = await _get('/predictions/farm/$farmId');
    final List list = data['predictions'] ?? data;
    return list.map((p) => Prediction.fromJson(p)).toList();
  }

  Future<PayoutRecord?> getPayoutById(String payoutId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return PayoutRecord.fromJson(_mockPayouts.first);
    }
    try { final data = await _get('/predictions/payout/$payoutId'); return PayoutRecord.fromJson(data); }
    catch (_) { return null; }
  }

  // ── Image Upload ───────────────────────────────────────────────────────────

  /// POST /images/upload/{farmer_id}  multipart → triggers AI → payout
  Future<Map<String, dynamic>> uploadCropImage(String farmerId, String imagePath, String token) async {
    if (mockMode) {
      await Future.delayed(const Duration(seconds: 2));
      return {
        'prediction_id': 'pred-mock-001',
        'disease_type': 'rice_blast',
        'confidence_score': 0.92,
        'payout_triggered': true,
        'payout_multiplier': 1.0,
        'affected_area_percent': 0.75,
        'bedrock_assessment': 'High confidence detection of Magnaporthe oryzae (rice blast). Satellite NDVI confirms 75% vegetation collapse. Full payout approved. You will receive an SMS confirmation shortly.',
      };
    }
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images/upload/$farmerId'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) throw Exception('Image upload failed: ${res.statusCode}');
    return jsonDecode(res.body);
  }

  // NOTE: POST /predictions/score is AI teammate only — frontend never calls this.
}