import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildActionPlanCard(),
          const SizedBox(height: 20),
          _buildZonesSection(),
          const SizedBox(height: 20),
          _buildLearningSection(),
          const SizedBox(height: 20),
          _buildProfessionalsSection(),
          const SizedBox(height: 20),
          _buildEmergencySection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.layers, color: Color(0xFFE040FB), size: 28),
            SizedBox(width: 8),
            Text(
              'Prévention',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFE040FB),
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Ressources et conseils',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE040FB), Color(0xFF40C4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Plan d\'Action',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plan personnalisé pour gérer crises',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Text('Ouvrir Plan', style: TextStyle(color: Color(0xFFE040FB), fontWeight: FontWeight.bold)),
              label: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE040FB)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.map, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Zones à Éviter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.error_outline, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          _buildZoneItem(
            'Centre-ville',
            'Pollution élevée',
            'Élevé',
            Icons.directions_car,
            Colors.red.shade50,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildZoneItem(String title, String subtitle, String severity, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.brown.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.school, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Apprendre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModuleCard(
          'Comprendre l\'Asthme',
          'Les bases de la maladie',
          '5 modules',
          '20 min',
          Icons.medical_services,
          Colors.red.shade100,
        ),
        const SizedBox(height: 12),
        _buildModuleCard(
          'Utiliser Inhalateur',
          'Techniques et bonnes pratiques',
          'Vidéo',
          '8 min',
          Icons.air,
          Colors.blue.shade100,
        ),
        const SizedBox(height: 12),
        _buildModuleCard(
          'Qualité de Vie',
          'Exercices et nutrition',
          '7 modules',
          '35 min',
          Icons.directions_run,
          Colors.green.shade100,
        ),
      ],
    );
  }

  Widget _buildModuleCard(String title, String subtitle, String tag1, String tag2, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag(tag1, Icons.grid_view),
                    const SizedBox(width: 8),
                    _buildTag(tag2, Icons.timer),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProfessionalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text(
                'Professionnels',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProfessionalItem(
            'Dr. Marie Dubois',
            'Pneumologue',
            '2.3 km',
            Icons.person,
            Colors.purple.shade50,
          ),
          const SizedBox(height: 12),
          _buildProfessionalItem(
            'Pharmacie Centre',
            'Pharmacie',
            '0.8 km',
            Icons.local_pharmacy,
            Colors.green.shade50,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalItem(String name, String role, String distance, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(role, style: const TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Urgences',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildEmergencyButton('15', 'SAMU', Icons.phone)),
              const SizedBox(width: 16),
              Expanded(child: _buildEmergencyButton('112', 'Urgences', Icons.sos)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(String number, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
