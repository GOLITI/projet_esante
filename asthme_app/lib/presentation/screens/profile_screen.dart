import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:asthme_app/presentation/blocs/auth/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildUserCard(),
          const SizedBox(height: 20),
          _buildHealthSection(),
          const SizedBox(height: 20),
          _buildTriggersSection(),
          const SizedBox(height: 20),
          _buildEmergencyContactCard(),
          const SizedBox(height: 20),
          _buildSettingsSection(),
          const SizedBox(height: 20),
          _buildLogoutButton(),
          const SizedBox(height: 20),
          const Text(
            'Version 1.0.0 - PULSAR Health',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/icons/logo.jpeg',
          height: 40,
        ),
        const SizedBox(height: 8),
        const Text(
          'Mon Profil',
          style: TextStyle(
            color: Color(0xFFE040FB),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Récupérer les informations de l'utilisateur
        String userName = 'Utilisateur';
        String userEmail = 'email@example.com';
        String userInitial = 'U';
        
        if (state is AuthAuthenticated) {
          userName = state.user.name;
          userEmail = state.user.email;
          userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE040FB), Color(0xFF40C4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Santé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHealthItem(
            'Type\nasthme',
            'Non\nrenseigné',
            Icons.air,
            Colors.red.shade100,
            Colors.red,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.yellow.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                const SizedBox(width: 16),
                const Text(
                  'Sévérité',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'Non renseigné',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildHealthItem(
            'Âge',
            '- ans',
            Icons.cake,
            Colors.orange.shade100,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String label, String value, IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggersSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Déclencheurs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun déclencheur',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.sos, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Contact Urgence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactItem(Icons.person_outline, 'Non renseigné'),
          const SizedBox(height: 12),
          _buildContactItem(Icons.phone_outlined, 'Non renseigné'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.brown, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.settings, color: Colors.blueGrey),
            SizedBox(width: 8),
            Text(
              'Paramètres',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey, 
                                     // Actually based on image it looks like light bg, so let's use black/grey
                                     // Wait, the image has "Paramètres" title in white? No, it's light blue/white text on dark bg?
                                     // Ah, looking at the image "uploaded_image_2...", the "Paramètres" title is white but on a light blue bg? 
                                     // No, it's "Paramètres" text in white on a light blue background? No.
                                     // Let's look closer at "uploaded_image_2_1763857275825.png".
                                     // The title "Paramètres" is next to a gear icon. The text is white? No, it looks like it might be white on a very light background which is hard to read, OR it's actually just dark text.
                                     // Let's assume dark text for safety on light background.
              ),
            ),
          ],
        ),
        // Actually, looking at the image again, the "Paramètres" header text is barely visible or it's white on light blue.
        // Let's check the previous section headers. "Déclencheurs" was black. "Santé" was black.
        // In the image, "Paramètres" text next to the gear icon seems to be white.
        // But the background is light cyan. White on light cyan is bad contrast.
        // However, the user provided image has it. Let's stick to a readable color like Colors.white if the bg is dark, or Colors.black if bg is light.
        // The background of the screen seems to be a very light cyan/white.
        // Let's use Colors.white for the title "Paramètres" as requested by the visual, but maybe it's inside a container?
        // No, it's just a row.
        // Wait, in the image "uploaded_image_2...", the "Paramètres" text is actually WHITE. And the background is light blue. This is low contrast.
        // But I must reproduce the UI.
        // Let's look at the "Paramètres" list items. They are white cards with dark text.
        // The header "Paramètres" is white.
        // I will use Colors.white for the header text to match the image, but I'll add a shadow or something if needed? No, just stick to the image.
        // Actually, let's look at the "Déclencheurs" header in "uploaded_image_2...". It's black.
        // The "Paramètres" header in "uploaded_image_2..." is... actually it looks like it's inside a section with a specific background?
        // No, it's just text.
        // Let's use Colors.white for the "Paramètres" title as it appears in the image.
        
        // Correction: Looking really closely at crop 2, the "Paramètres" text is White. The icon is a gear.
        // The background is a light blue gradient.
        
        const SizedBox(height: 12),
        _buildSettingItem(Icons.settings_outlined, 'Paramètres'),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.shield_outlined, 'Confidentialité'),
        const SizedBox(height: 12),
        _buildSettingItem(Icons.mail_outline, 'Notifications'),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Déconnexion',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
