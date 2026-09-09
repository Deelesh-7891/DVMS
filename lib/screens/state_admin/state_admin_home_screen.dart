import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';

/// Dashboard for a StateAdmin. Data displayed here must be filtered by the
/// authenticated user's state by the API, never by Flutter alone.
class StateAdminHomeScreen extends StatefulWidget {
  const StateAdminHomeScreen({super.key});

  @override
  State<StateAdminHomeScreen> createState() => _StateAdminHomeScreenState();
}

class _StateAdminHomeScreenState extends State<StateAdminHomeScreen> {
  String _name = 'State Admin';
  String _state = 'Assigned state';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = prefs.getString('fullName')?.trim().isNotEmpty == true
          ? prefs.getString('fullName')!.trim()
          : _name;
      _state = prefs.getString('stateName')?.trim().isNotEmpty == true
          ? prefs.getString('stateName')!.trim()
          : _state;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Administration'),
        backgroundColor: const Color(0xff2458A6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome, $_name', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Scope: $_state', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          const _AdminAction(
            icon: Icons.account_tree_outlined,
            title: 'Branch overview',
            message: 'View only branches assigned to your state.',
          ),
          const _AdminAction(
            icon: Icons.directions_car_outlined,
            title: 'Vehicles and compliance',
            message: 'Review vehicle, insurance, service, and document status.',
          ),
          const _AdminAction(
            icon: Icons.fact_check_outlined,
            title: 'Approvals',
            message: 'Approve requests that belong to your state.',
          ),
          const _AdminAction(
            icon: Icons.assessment_outlined,
            title: 'State reports',
            message: 'Create reports limited to your state data.',
          ),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff2458A6)),
        title: Text(title),
        subtitle: Text(message),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
