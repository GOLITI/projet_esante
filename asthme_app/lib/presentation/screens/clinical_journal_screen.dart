import 'package:flutter/material.dart';
import '../../../data/datasources/local_database.dart';

/// Formulaire de saisie du journal clinique basé sur le dataset
class ClinicalJournalScreen extends StatefulWidget {
  const ClinicalJournalScreen({super.key});

  @override
  State<ClinicalJournalScreen> createState() => _ClinicalJournalScreenState();
}

class _ClinicalJournalScreenState extends State<ClinicalJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Symptômes (colonnes du dataset)
  final Map<String, bool> _symptoms = {
    'tiredness': false,
    'dry_cough': false,
    'difficulty_breathing': false,
    'sore_throat': false,
    'pains': false,
    'nasal_congestion': false,
    'runny_nose': false,
  };
  
  // Infos cliniques
  String? _inhalerUsage;
  String? _diseaseControl;
  String? _exacerbationHistory;

  Future<void> _submitJournal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final db = await LocalDatabase.instance.database;
      
      // Composer la chaîne de symptômes
      final symptomsList = _symptoms.entries
          .where((e) => e.value)
          .map((e) => e.key.replaceAll('_', ' '))
          .join(', ');

      // Composer les données en JSON pour un meilleur affichage
      final Map<String, dynamic> journalData = {
        'symptoms': symptomsList.isEmpty ? "Aucun symptôme" : symptomsList,
        if (_inhalerUsage != null) 'inhaler': _inhalerUsage,
        if (_diseaseControl != null) 'control': _diseaseControl,
        if (_exacerbationHistory != null) 'exacerbation': _exacerbationHistory,
      };

      // Créer une chaîne formatée lisible
      final symptomsText = symptomsList.isEmpty ? "Aucun symptôme" : symptomsList;

      // Enregistrer l'auto-rapport clinique
      // On sauvegarde dans predictions avec risk_level = -1 (journal manuel)
      await db.insert('predictions', {
        'user_id': 1,
        'sensor_data_id': null, // Pas de données capteur pour un auto-rapport
        'risk_level': -1, // Indicateur de journal manuel (pas une prédiction ML)
        'risk_probability': 0.0,
        'symptoms': symptomsText,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entrée du journal enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Clinique'),
        backgroundColor: const Color(0xFFE040FB),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildSectionHeader('Symptômes Ressentis', Icons.sick_outlined),
            const SizedBox(height: 12),
            _buildSymptomsSection(),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Auto-évaluation Clinique', Icons.medical_information),
            const SizedBox(height: 12),
            _buildClinicalSection(),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitJournal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE040FB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Enregistrer l\'entrée', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE040FB), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE040FB),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSymptomCheckbox('Fatigue', 'tiredness'),
            _buildSymptomCheckbox('Toux sèche', 'dry_cough'),
            _buildSymptomCheckbox('Difficulté respiratoire', 'difficulty_breathing'),
            _buildSymptomCheckbox('Mal de gorge', 'sore_throat'),
            _buildSymptomCheckbox('Douleurs', 'pains'),
            _buildSymptomCheckbox('Congestion nasale', 'nasal_congestion'),
            _buildSymptomCheckbox('Nez qui coule', 'runny_nose'),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCheckbox(String label, String key) {
    return CheckboxListTile(
      title: Text(label),
      value: _symptoms[key],
      onChanged: (value) => setState(() => _symptoms[key] = value ?? false),
      activeColor: const Color(0xFFE040FB),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildClinicalSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage de l\'inhalateur de secours (dernières 24h)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _inhalerUsage,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucun')),
                DropdownMenuItem(value: '1-2', child: Text('1-2 fois')),
                DropdownMenuItem(value: '3-5', child: Text('3-5 fois')),
                DropdownMenuItem(value: 'more', child: Text('Plus de 5 fois')),
              ],
              onChanged: (value) => setState(() => _inhalerUsage = value),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Niveau de contrôle de la maladie',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _diseaseControl,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'good', child: Text('Bien contrôlé')),
                DropdownMenuItem(value: 'partial', child: Text('Partiellement contrôlé')),
                DropdownMenuItem(value: 'poor', child: Text('Non contrôlé')),
              ],
              onChanged: (value) => setState(() => _diseaseControl = value),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Antécédents d\'exacerbation (dernier mois)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _exacerbationHistory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucune')),
                DropdownMenuItem(value: 'mild', child: Text('Légère')),
                DropdownMenuItem(value: 'moderate', child: Text('Modérée')),
                DropdownMenuItem(value: 'severe', child: Text('Sévère')),
              ],
              onChanged: (value) => setState(() => _exacerbationHistory = value),
            ),
          ],
        ),
      ),
    );
  }
}
