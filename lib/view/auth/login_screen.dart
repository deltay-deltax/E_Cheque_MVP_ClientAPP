import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../core/services/prefs_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool rememberMe = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.account_balance, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 32),
            Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sign in to your account to continue",
              style: TextStyle(fontSize: 17, color: AppColors.mutedText),
            ),
            const SizedBox(height: 30),
            CustomTextField(
              controller: emailController,
              hintText: "Email",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: passwordController,
              hintText: "Password",
              prefixIcon: Icons.lock,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (val) => setState(() => rememberMe = val ?? false),
                ),
                const Text("Remember me"),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.forgot);
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: "Sign In",
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text;
                try {
                  setState(() => _loading = true);
                  await AuthService.instance.signInWithEmail(
                    email: email,
                    password: password,
                  );
                  await PrefsService.instance.setRememberMe(rememberMe);
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                } on FirebaseAuthException catch (e) {
                  final msg = e.message ?? 'Auth error: ${e.code}';
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                } catch (e) {
                  final msg = e.toString();
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              fillColor: AppColors.primaryBlue,
            ),
            const SizedBox(height: 36),
            Row(
              children: const <Widget>[
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      setState(() => _loading = true);
                      await AuthService.instance.signInWithGoogle();
                      await PrefsService.instance.setRememberMe(true);
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                    } on FirebaseAuthException catch (e) {
                      String msg;
                      switch (e.code) {
                        case 'account-exists-with-different-credential':
                          msg = 'Account exists with different sign-in method.';
                          break;
                        case 'invalid-credential':
                          msg = 'Invalid credential. Try again.';
                          break;
                        case 'user-disabled':
                          msg = 'Account disabled. Contact support.';
                          break;
                        default:
                          msg = 'Google sign-in failed. Try again.';
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } catch (e) {
                      String msg;
                      final err = e.toString();
                      if (err.contains('not_registered')) {
                        msg = 'Not registered. Please register first.';
                      } else if (err.contains('bank_email_not_registered')) {
                        msg = 'Use your bank-registered email.';
                      } else if (err.contains('sign_in_cancelled')) {
                        msg = 'Sign-in cancelled.';
                      } else {
                        msg = 'Google sign-in failed. Try again.';
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.apple, size: 20),
                  label: const Text('Apple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.grey200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account?",
                  style: TextStyle(fontSize: 17, color: AppColors.mutedText),
                  children: [
                    TextSpan(
                      text: " Sign Up",
                      style: TextStyle(
                        color: AppColors.primaryBlue,

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
          ),
          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
