import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _role = 'parent';
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final db = Supabase.instance.client;

      final res = await db.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (res.user == null) throw Exception('Sign up failed');

      // Create profile row
      await db.from('users').insert({
        'auth_user_id': res.user!.id,
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': _role,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Check your email to verify.'),
          backgroundColor: AppColors.green,
        ),
      );
      context.go('/login');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/login'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.directions_bus_rounded, size: 44, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join SafeRoute today',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Role selector
                          Row(
                            children: [
                              Expanded(
                                child: _RoleChip(
                                  label: 'Parent',
                                  icon: Icons.family_restroom_rounded,
                                  selected: _role == 'parent',
                                  onTap: () => setState(() => _role = 'parent'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleChip(
                                  label: 'Driver',
                                  icon: Icons.drive_eta_rounded,
                                  selected: _role == 'driver',
                                  onTap: () => setState(() => _role = 'driver'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _Field(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _emailCtrl,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter email';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _passCtrl,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                                  size: 20, color: AppColors.textSecondary),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 8) return 'Minimum 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            controller: _confirmCtrl,
                            label: 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscure: _obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                  color: AppColors.textSecondary),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) {
                              if (v != _passCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _loading ? null : _signup,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              backgroundColor: AppColors.primary,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Create Account',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ',
                                  style: TextStyle(color: AppColors.textSecondary)),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
