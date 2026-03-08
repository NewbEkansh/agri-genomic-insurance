export interface Farmer {
  farmer_id: string; name: string; phone: string; wallet_address: string;
  crop_type: string; farm_lat: number; farm_lon: number;
  farm_area_hectares: number; language: string;
  agro_polygon_id: string; baseline_ndvi: number; created_at: string;
}
export interface FarmerInput {
  name: string; phone: string; wallet_address: string; crop_type: string;
  farm_lat: number; farm_lon: number; farm_area_hectares: number; language: string;
}
export interface SoilData {
  soil_moisture: number; soil_temp_celsius: number; surface_temp_celsius: number;
}
export interface NdviAnalysis {
  delta: number; pct_drop: number;
  severity: 'healthy' | 'stressed' | 'severe' | 'critical'; fraud_flag: boolean;
}
export interface FarmHealth {
  farmer_id: string; current_ndvi: number; baseline_ndvi: number;
  soil_data: SoilData; ndvi_analysis: NdviAnalysis;
}
export interface Policy {
  policy_id: string; farmer_id: string; insured_amount_usdc: number;
  status: 'active' | 'triggered' | 'paid' | 'cancelled'; created_at: string;
}
export interface Prediction {
  prediction_id: string; disease_type: string; confidence_score: number;
  affected_area_percent: number; payout_triggered: boolean; payout_multiplier: number;
  regional_consensus_pct: number; bedrock_assessment: string;
  payout_id: string | null; created_at: string;
}
export interface PayoutRecord {
  payout_id: string; farm_id: string; farmer_wallet: string;
  insured_amount_usdc: number; payout_multiplier: number; final_payout_usdc: number;
  tx_hash: string; status: 'pending' | 'submitted' | 'confirmed' | 'failed'; created_at: string;
}
