import 'package:echeque_mvp/view/widgets/custom_button.dart';
import 'package:echeque_mvp/view/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeToTerms = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back arrow
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),

                // Heading
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Join us and start managing your finances",
                  style: TextStyle(fontSize: 16, color: AppColors.grey600),
                ),
                const SizedBox(height: 32),

                // Input Fields
                CustomTextField(
                  controller: nameController,
                  hintText: "Full Name",
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  hintText: "Email",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: phoneController,
                  hintText: "Phone Number",
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  prefixText: '+91 ',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: passwordController,
                  hintText: "Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.grey600,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.grey600,
                    ),
                    onPressed: () => setState(
                      () => obscureConfirmPassword = !obscureConfirmPassword,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Terms Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: agreeToTerms,
                      onChanged: (val) =>
                          setState(() => agreeToTerms = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppColors.primaryBlue,
                    ),
                    Expanded(
                      child: Wrap(
                        children: [
                          Text(
                            "I agree to the ",
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              "Terms of Service",
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            " and ",
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              "Privacy Policy",
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Create Account Button
                CustomButton(
                  text: "Create Account",
                  onPressed: agreeToTerms
                      ? () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text;
                          final confirm = confirmPasswordController.text;
                          final fullName = nameController.text.trim();
                          final phone = phoneController.text.trim();

                          if (password != confirm) {
                            // minimal feedback for mismatch
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match')),
                            );
                            return;
                          }

                          try {
                            setState(() => _loading = true);
                            await AuthService.instance.signUpWithEmail(
                              email: email,
                              password: password,
                              fullName: fullName,
                              phone: phone.isEmpty ? null : phone,
                            );
                            if (!mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (route) => false,
                            );
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
                        }
                      : null,
                  isEnabled: agreeToTerms,
                  fillColor: AppColors.primaryBlue,
                ),

                const SizedBox(height: 32),

                // Sign in
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.mutedText,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign in",
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
            ),
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
