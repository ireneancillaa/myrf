import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _primaryGreen = Color(0xFF22C55E);
  static const Color _primaryGreenLight = Color(0xFF6ED99A);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _errorColor = Color(0xFFDC2626);
  static const Color _warningColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    const userName = 'Breeder';
    const email = 'breeder@myrf.local';
    const role = 'BREEDER';
    const farmName = 'My Research Farm';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryGreen, _primaryGreenLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: _primaryGreen,
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('User Information'),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.person_outline,
              label: 'Name',
              value: userName,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: role,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.agriculture_outlined,
              label: 'Farm Name',
              value: farmName,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('App Information'),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.info_outline,
              label: 'Version',
              value: '1.0.0',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.build_outlined,
              label: 'Build',
              value: '2024.01.001',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: _errorColor),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: _errorColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: _errorColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact admin to delete account'),
                      backgroundColor: _textSecondary,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever, color: _errorColor),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(color: _errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryGreen),
        ),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: _warningColor),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(backgroundColor: _errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
