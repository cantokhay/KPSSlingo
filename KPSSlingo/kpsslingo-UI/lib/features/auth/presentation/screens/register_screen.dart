import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_notifier.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/core/providers/theme_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String _selectedLevel = 'lisans';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authNotifierProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _usernameController.text.trim(),
            _selectedLevel,
          );
      
      final authState = ref.read(authNotifierProvider);
      if (authState.status == AuthStatus.authenticated) {
        if (mounted) context.go('/home');
      } else if (authState.status == AuthStatus.verificationPending) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
              title: const Text('E-posta Doğrulama', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_rounded, size: 64, color: AppColors.primary),
                  Gaps.md,
                  const Text(
                    'Kayıt başarılı! Lütfen e-posta adresinize gönderilen doğrulama bağlantısına tıklayın.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/auth/login');
                  },
                  child: const Text('Giriş Ekranına Git'),
                ),
              ],
            ),
          );
        }
      } else if (authState.status == AuthStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authState.errorMessage ?? 'Hata oluştu')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/login'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? Colors.amber : AppColors.primary,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleDarkLight(isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gaps.xxl,
                Text(
                  'Merhaba! 👋',
                  style: AppTextStyles.displayLarge.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                Gaps.sm,
                Text(
                  'Yeni bir hesap oluştur ve KPSS yolculuğuna başla.',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                Gaps.xl,
                
                // Username
                _buildTextField(
                  label: 'Kullanıcı Adı',
                  controller: _usernameController,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                ),
                Gaps.md,

                // Email
                _buildTextField(
                  label: 'E-posta',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Gerekli';
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Geçersiz e-posta';
                    return null;
                  },
                ),
                Gaps.md,

                // Password
                _buildTextField(
                  label: 'Şifre',
                  controller: _passwordController,
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Gerekli';
                    if (v.length < 6) return 'En az 6 karakter';
                    if ((v.replaceAll(RegExp(r'[^a-zA-Z]'), '').length) < 2) return 'En az 2 harf içermeli';
                    if (RegExp(r'(.)\1{2,}').hasMatch(v)) return 'Zayıf şifre (örn: 111, aaa)';
                    return null;
                  },
                ),
                Gaps.xl,
                
                Text(
                  'Hedef Sınavını Seç',
                  style: AppTextStyles.labelBold.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.left,
                ),
                Gaps.sm,
                _buildLevelCard(
                  title: 'Lisans',
                  description: 'Üniversite mezunları için',
                  value: 'lisans',
                  color: AppColors.error,
                ),
                Gaps.sm,
                _buildLevelCard(
                  title: 'Önlisans',
                  description: '2 yıllık mezunlar için',
                  value: 'onlisans',
                  color: AppColors.primary,
                ),
                Gaps.sm,
                _buildLevelCard(
                  title: 'Ortaöğretim',
                  description: 'Lise mezunları için',
                  value: 'ortaogretim',
                  color: AppColors.success,
                ),
                Gaps.xl,

                ElevatedButton(
                  onPressed: authState.status == AuthStatus.loading ? null : _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  ),
                  child: authState.status == AuthStatus.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kayıt Ol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                Gaps.lg,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten hesabın var mı? '),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: (_) => _onRegister(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String description,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelBold.copyWith(
                    color: isSelected ? color : null,
                    fontSize: 14,
                  )),
                  Text(description, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
