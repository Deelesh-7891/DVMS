import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService auth = AuthService();
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();

  List<dynamic> roles = [];
  List<dynamic> states = [];
  List<dynamic> cities = [];

  int? roleId;
  String role = '';
  final List<int> stateIds = [];
  final List<int> cityIds = [];

  bool loading = true;
  bool busy = false;
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final a = await auth.roles();
      final b = await auth.states();
      if (!mounted) return;
      setState(() {
        roles = a['data'] ?? [];
        states = b['data'] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load login data: $e')),
      );
    }
  }

  bool stateReq() => const [
        'StateAdmin',
        'BranchAdmin',
        'Security',
        'Driver',
        'Accounts',
      ].contains(role);

  bool cityReq() => const [
        'BranchAdmin',
        'Driver',
        'Accounts',
      ].contains(role);

  Future<void> stateChanged(int id, bool selected) async {
    setState(() {
      if (selected) {
        if (!stateIds.contains(id)) stateIds.add(id);
      } else {
        stateIds.remove(id);
      }
      cityIds.clear();
      cities.clear();
    });

    if (!cityReq() || stateIds.isEmpty) return;

    final List<dynamic> loaded = [];
    for (final sid in stateIds) {
      try {
        final result = await auth.cities(sid);
        final data = result['data'];
        if (data is List) loaded.addAll(data);
      } catch (e) {
        debugPrint('Cities error for state $sid: $e');
      }
    }

    if (!mounted) return;
    setState(() => cities = loaded);
  }

  Future<Position> gps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Please enable GPS/location service');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required for Security login');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> signIn() async {
    if (roleId == null ||
        email.text.trim().isEmpty ||
        pass.text.isEmpty ||
        (stateReq() && stateIds.isEmpty) ||
        (cityReq() && cityIds.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => busy = true);

    try {
      double? lat;
      double? lng;

      if (role.toLowerCase() == 'security') {
        final Position p = await gps();
        lat = p.latitude;
        lng = p.longitude;
      }

      final d = await auth.login(
        email.text.trim(),
        pass.text,
        roleId!,
        stateIds,
        cityIds,
        lat,
        lng,
      );

      final prefs = await SharedPreferences.getInstance();
      final user = d['user'] is Map ? d['user'] as Map : <String, dynamic>{};
      final token = (d['token'] ?? '').toString();
      final loggedRole = (user['RoleName'] ?? role).toString();

      await prefs.setString('token', token);
      await prefs.setBool('isLogin', true);
      await prefs.setString('roleName', loggedRole);
      await prefs.setString('role', loggedRole);
      await prefs.setString('fullName', (user['FullName'] ?? '').toString());
      await prefs.setString('email', (user['Email'] ?? email.text.trim()).toString());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void showForgot(BuildContext context) {
    final controller = TextEditingController(text: email.text.trim());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await auth.forgot(controller.text.trim());
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP sent successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            },
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                margin: const EdgeInsets.all(8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.directions_car, size: 70),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Demo Vehicle Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: roleId,
                        decoration: const InputDecoration(
                          labelText: 'User Type',
                          border: OutlineInputBorder(),
                        ),
                        items: roles.map<DropdownMenuItem<int>>((r) {
                          final id = int.tryParse('${r['RoleId']}');
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text('${r['RoleName']}'),
                          );
                        }).toList(),
                        onChanged: loading
                            ? null
                            : (id) {
                                if (id == null) return;
                                final r = roles.firstWhere(
                                  (x) => int.tryParse('${x['RoleId']}') == id,
                                );
                                setState(() {
                                  roleId = id;
                                  role = '${r['RoleName']}';
                                  stateIds.clear();
                                  cityIds.clear();
                                  cities.clear();
                                });
                              },
                      ),
                      if (stateReq()) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'State',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: states.length,
                            itemBuilder: (_, i) {
                              final s = states[i];
                              final id = int.tryParse('${s['StateId']}') ?? 0;
                              final name = '${s['StateName'] ?? s['Name'] ?? ''}';
                              return CheckboxListTile(
                                dense: true,
                                title: Text(name),
                                value: stateIds.contains(id),
                                onChanged: (v) => stateChanged(id, v ?? false),
                              );
                            },
                          ),
                        ),
                      ],
                      if (cityReq()) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: cityIds.isNotEmpty ? cityIds.first : null,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                          items: cities.map<DropdownMenuItem<int>>((x) {
                            final id = int.tryParse('${x['CityId'] ?? x['Id']}');
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text('${x['CityName'] ?? x['Name'] ?? ''}'),
                            );
                          }).toList(),
                          onChanged: (id) {
                            setState(() {
                              cityIds
                                ..clear()
                                ..addAll(id == null ? <int>[] : <int>[id]);
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pass,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: busy ? null : signIn,
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sign in'),
                        ),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => showForgot(context),
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
