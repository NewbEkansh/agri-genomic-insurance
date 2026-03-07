import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farmer_model.dart';

class ApiService {
  // For Android emulator use: http://10.0.2.2:8000
  // For physical device use: http://YOUR_MACHINE_IP:8000
  // For iOS simulator use: http://localhost:8000
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const bool mockMode = true; // Set to false when backend is live

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
    'soil_data': {
      'moisture': 21.0,
      'temperature': 31.2,
      'humidity': 58.0,
    },
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

  // ── API Methods ────────────────────────────────────────────────────────────
  // NOTE: Paths match the backend FastAPI routes from the integration guide

  Future<Farmer> getFarmer(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Farmer.fromJson(_mockFarmer);
    }
    // GET /farmers/{farmer_id}
    final res = await http.get(Uri.parse('$baseUrl/farmers/$farmerId'));
    if (res.statusCode != 200) throw Exception('Failed to load farmer');
    return Farmer.fromJson(jsonDecode(res.body));
  }

  Future<FarmHealth> getFarmHealth(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return FarmHealth.fromJson(_mockHealth);
    }
    // GET /farmers/{farmer_id}/farm-health
    final res = await http.get(Uri.parse('$baseUrl/farmers/$farmerId/farm-health'));
    if (res.statusCode != 200) throw Exception('Failed to load farm health');
    return FarmHealth.fromJson(jsonDecode(res.body));
  }

  Future<Prediction?> getLatestPrediction(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      return Prediction.fromJson(_mockPrediction);
    }
    // GET /predictions/farm/{farm_id}
    final res = await http.get(Uri.parse('$baseUrl/predictions/farm/$farmerId'));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw Exception('Failed to load prediction');
    final data = jsonDecode(res.body);
    final predictions = data['predictions'] as List?;
    if (predictions == null || predictions.isEmpty) return null;
    return Prediction.fromJson(predictions.first);
  }

  Future<List<PayoutRecord>> getPayoutHistory(String farmerId) async {
    if (mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockPayouts.map((p) => PayoutRecord.fromJson(p)).toList();
    }
    // GET /farmers/{farmer_id}/payouts
    final res = await http.get(Uri.parse('$baseUrl/farmers/$farmerId/payouts'));
    if (res.statusCode != 200) throw Exception('Failed to load payouts');
    final data = jsonDecode(res.body);
    final payouts = data['payouts'] as List? ?? [];
    return payouts.map((p) => PayoutRecord.fromJson(p)).toList();
  }
}