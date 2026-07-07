import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/demo_service.dart';
import '../../../core/theme/app_theme.dart';

class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
            stops: [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.directions_bus_rounded, size: 56, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'SafeRoute',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'School bus safety platform',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Continue as',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RoleButton(
                      icon: Icons.drive_eta_rounded,
                      title: 'Driver',
                      subtitle: 'Start trips and manage stops',
                      iconBg: AppColors.primary,
                      onTap: () { DemoService.enter(); context.go('/driver'); },
                    ),
                    const SizedBox(height: 14),
                    _RoleButton(
                      icon: Icons.family_restroom_rounded,
                      title: 'Parent',
                      subtitle: 'Track your child\'s bus live',
                      iconBg: const Color(0xFF0D8A4E),
                      onTap: () { DemoService.enter(); context.go('/parent'); },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Demo mode · Auth coming soon',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
