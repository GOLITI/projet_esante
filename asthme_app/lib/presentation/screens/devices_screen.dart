import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.link, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text(
                'Connectés',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDeviceCard(),
          const SizedBox(height: 20),
          _buildGuideCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.bluetooth, color: Color(0xFFE040FB), size: 28),
            SizedBox(width: 8),
            Text(
              'Mes Appareils',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE040FB),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade800,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.green.shade800),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synchronisé',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Il y a 5 min',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
            ],
          ),
          Icon(Icons.refresh, color: Colors.green.shade700),
        ],
      ),
    );
  }

  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.air, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inhalateur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.bluetooth, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'SmartBreath Pro',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Actif',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.shade100),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medication, color: Colors.orange, size: 24),
                      SizedBox(height: 12),
                      Text(
                        'Doses\nrestantes',
                        style: TextStyle(color: Colors.blueGrey, height: 1.2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '142/200',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.battery_std, color: Colors.green.shade700, size: 24),
                      const SizedBox(height: 12),
                      const Text(
                        'Batterie',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '87%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Colors.blue.shade800),
              const SizedBox(width: 12),
              Text(
                'Guide Connexion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepItem(1, 'Activez Bluetooth sur appareil'),
          const SizedBox(height: 16),
          _buildStepItem(2, 'Mode appairage sur dispositif médical'),
          const SizedBox(height: 16),
          _buildStepItem(3, 'Cliquez "Ajouter"'),
          const SizedBox(height: 16),
          _buildStepItem(4, 'Confirmez code si demandé'),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
