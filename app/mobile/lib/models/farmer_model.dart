class Farmer {
  final String name;
  final String farmId;
  final String walletAddress;
  final String location;
  final double insuredAmountEth;
  final String cropType;

  Farmer({
    required this.name,
    required this.farmId,
    required this.walletAddress,
    required this.location,
    required this.insuredAmountEth,
    required this.cropType,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
        name: json['name'],
        farmId: json['farm_id'],
        walletAddress: json['wallet_address'],
        location: json['location'],
        insuredAmountEth: (json['insured_amount_eth'] as num).toDouble(),
        cropType: json['crop_type'],
      );
}

class FarmHealth {
  final double ndvi;
  final String severity; // healthy | stressed | critical
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final DateTime updatedAt;

  FarmHealth({
    required this.ndvi,
    required this.severity,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.updatedAt,
  });

  factory FarmHealth.fromJson(Map<String, dynamic> json) => FarmHealth(
        ndvi: (json['current_ndvi'] as num).toDouble(),
        severity: json['severity'],
        soilMoisture: (json['soil_data']['moisture'] as num).toDouble(),
        temperature: (json['soil_data']['temperature'] as num).toDouble(),
        humidity: (json['soil_data']['humidity'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updated_at']),
      );
}

class Prediction {
  final String diseaseType;
  final double confidenceScore;
  final String bedrockAssessment;
  final int payoutPercent;
  final DateTime detectedAt;

  Prediction({
    required this.diseaseType,
    required this.confidenceScore,
    required this.bedrockAssessment,
    required this.payoutPercent,
    required this.detectedAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
        diseaseType: json['disease_type'],
        confidenceScore: (json['confidence_score'] as num).toDouble(),
        bedrockAssessment: json['bedrock_assessment'],
        payoutPercent: json['payout_percent'],
        detectedAt: DateTime.parse(json['detected_at']),
      );
}

class PayoutRecord {
  final String txHash;
  final double amountEth;
  final int payoutPercent;
  final String diseaseType;
  final String status;
  final DateTime timestamp;

  PayoutRecord({
    required this.txHash,
    required this.amountEth,
    required this.payoutPercent,
    required this.diseaseType,
    required this.status,
    required this.timestamp,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> json) => PayoutRecord(
        txHash: json['tx_hash'],
        amountEth: (json['amount_eth'] as num).toDouble(),
        payoutPercent: json['payout_percent'],
        diseaseType: json['disease_type'],
        status: json['status'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}