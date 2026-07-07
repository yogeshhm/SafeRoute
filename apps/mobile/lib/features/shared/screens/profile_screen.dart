import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/demo_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = Supabase.instance.client;
      final authUser = db.auth.currentUser;
      Map<String, dynamic> profile;

      if (authUser != null) {
        profile = await db
            .from('users')
            .select('id, full_name, role, phone, email')
            .eq('auth_user_id', authUser.id)
            .single();
      } else {
        // demo — load whichever role is active based on the DemoService
        profile = await db
            .from('users')
            .select('id, full_name, role, phone, email')
            .eq('id', '00000000-0000-4000-8000-000000000102')
            .single();
      }

      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocationService.instance.stopTracking();
    await UserService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      _initials(_profile?['full_name'] ?? ''),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _profile?['full_name'] ?? '—',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _RoleBadge(role: _profile?['role'] ?? ''),
                  if (DemoService.isDemo) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Demo Mode',
                          style: TextStyle(color: AppColors.orange, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _profile?['email'] ?? '—',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _profile?['phone'] ?? '—',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: _capitalize(_profile?['role'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                          title: const Text('App Version'),
                          trailing: const Text('1.0.0',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: AppColors.red),
                      label: const Text('Sign Out',
                          style: TextStyle(color: AppColors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.red),
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = role == 'driver' ? AppColors.primary : AppColors.green;
    final icon = role == 'driver' ? Icons.drive_eta_rounded : Icons.family_restroom_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            role.isEmpty ? '—' : '${role[0].toUpperCase()}${role.substring(1)}',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      subtitle: Text(value,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
    );
  }
}
