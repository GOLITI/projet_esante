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
          _buildCrisisActionPlan(),
          const SizedBox(height: 20),
          _buildLearningSection(),
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

  Widget _buildCrisisActionPlan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Plan d\'Action pour Gérer Crises',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionStep(
            '1',
            'Reconnaître les signes',
            'Toux, respiration sifflante, oppression thoracique, essoufflement',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildActionStep(
            '2',
            'Utiliser inhalateur de secours',
            'Prendre 2-4 bouffées. Attendre 5-10 minutes pour évaluer',
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildActionStep(
            '3',
            'S\'éloigner des déclencheurs',
            'Air froid, fumée, allergènes, pollution, effort intense',
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildActionStep(
            '4',
            'Appeler à l\'aide si nécessaire',
            'Si aucune amélioration après 10 min, contactez urgences (185)',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionStep(String number, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearningSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text(
                'Apprendre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLearningModule(
            'Comprendre l\'Asthme',
            'L\'asthme est une maladie inflammatoire chronique des voies respiratoires. Elle se caractérise par des épisodes récurrents de respiration sifflante, d\'essoufflement et de toux. Les bronches deviennent enflammées et rétrécies, limitant le flux d\'air.',
            Icons.medical_services,
            Colors.red.shade100,
          ),
          const SizedBox(height: 16),
          _buildLearningModule(
            'Utiliser l\'Inhalateur',
            'Agitez l\'inhalateur 5 fois. Expirez complètement. Placez l\'embout dans votre bouche, appuyez et inspirez lentement et profondément. Retenez votre souffle 10 secondes puis expirez doucement.',
            Icons.air,
            Colors.blue.shade100,
          ),
          const SizedBox(height: 16),
          _buildLearningModule(
            'Qualité de Vie',
            'Maintenez une activité physique régulière adaptée (natation, marche). Adoptez une alimentation équilibrée riche en fruits et légumes. Évitez les déclencheurs (fumée, allergènes, air froid). Dormez suffisamment et gérez votre stress.',
            Icons.directions_run,
            Colors.green.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningModule(String title, String content, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
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
              Expanded(child: _buildEmergencyButton('185', 'SAMU', Icons.local_hospital)),
              const SizedBox(width: 12),
              Expanded(child: _buildEmergencyButton('1304', 'SOS Abidjan', Icons.emergency)),
            ],
          ),
          const SizedBox(height: 12),
          _buildEmergencyButton('07 49 96 0324', 'Urgence Privée', Icons.phone),
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
