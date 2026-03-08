import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/farmer_model.dart';

class FarmHealthWidget extends StatelessWidget {
  final FarmHealth health;

  const FarmHealthWidget({super.key, required this.health});

  Color get _severityColor {
    switch (health.severity) {
      case 'healthy':
        return const Color(0xFF4CAF50);
      case 'stressed':
        return const Color(0xFFFF9800);
      case 'critical':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _severityLabel {
    switch (health.severity) {
      case 'healthy':
        return 'Healthy';
      case 'stressed':
        return 'Stressed';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  IconData get _severityIcon {
    switch (health.severity) {
      case 'healthy':
        return Icons.eco;
      case 'stressed':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.crisis_alert;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _severityColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Farm Health',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _severityColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_severityIcon, color: _severityColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _severityLabel,
                      style: TextStyle(
                        color: _severityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // NDVI Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NDVI Score',
                style: TextStyle(color: Color(0xFF666666), fontSize: 14),
              ),
              Text(
                health.ndvi.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // NDVI Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: health.ndvi,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(_severityColor),
              minHeight: 12,
            ),
          ).animate().slideX(begin: -0.3, duration: 600.ms, curve: Curves.easeOut),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0.0', style: TextStyle(color: Color(0xFF999999), fontSize: 11)),
              Text('Dead', style: TextStyle(color: Color(0xFF999999), fontSize: 11)),
              Text('Dense', style: TextStyle(color: Color(0xFF999999), fontSize: 11)),
              Text('1.0', style: TextStyle(color: Color(0xFF999999), fontSize: 11)),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          // Soil Data Grid
          Row(
            children: [
              _SoilCard(
                label: 'Moisture',
                value: '${health.soilMoisture.toInt()}%',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 12),
              _SoilCard(
                label: 'Temp',
                value: '${health.temperature.toStringAsFixed(1)}°C',
                icon: Icons.thermostat_outlined,
                color: const Color(0xFFFF5722),
              ),
              const SizedBox(width: 12),
              _SoilCard(
                label: 'Humidity',
                value: '${health.humidity.toInt()}%',
                icon: Icons.cloud_outlined,
                color: const Color(0xFF9C27B0),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}

class _SoilCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SoilCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}