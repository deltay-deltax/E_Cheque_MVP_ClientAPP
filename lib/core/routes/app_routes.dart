import 'package:flutter/material.dart';

import '../../view/splash/splash1_screen.dart';
import '../../view/splash/splash2_screen.dart';
import '../../view/splash/splash3_screen.dart';
import '../../view/splash/splash4_screen.dart';
import '../../view/auth/login_screen.dart';
import '../../view/auth/signup_screen.dart';
import '../../view/auth/success_screen.dart';
import '../../view/auth/forgot_password_screen.dart';
import '../../view/home/home_screen.dart';
import '../../view/transaction_pin/enter_pin_screen.dart';
import '../../view/transaction_pin/create_pin_screen.dart';
import '../../view/transaction_pin/confirm_pin_screen.dart';
import '../../view/transaction_pin/pin_set_success_screen.dart';
import '../../view/link_bank/bank_add_modal_screen.dart';
import '../../view/link_bank/bank_info_screen.dart';
import '../../view/link_bank/link_with_mobile_screen.dart';
import '../../view/root_gate.dart';
import '../../view/chat/chat_screen.dart';

class AppRoutes {
  // Splash/Auth
  static const String root = '/';
  static const String splash1 = '/splash1';
  static const String splash2 = '/splash2';
  static const String splash3 = '/splash3';
  static const String splash4 = '/splash4';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String authSuccess = '/success';
  static const String forgot = '/forgot';

  // Home
  static const String home = '/home';
  static const String chat = '/chat';
  static const String bankAdd = '/bank/add';
  static const String bankInfo = '/bank/info';
  static const String linkWithMobile = '/bank/link-mobile';

  // Transaction PIN flow
  static const String pinEnter = '/pin/enter';
  static const String pinCreate = '/pin/create';
  static const String pinConfirm = '/pin/confirm';
  static const String pinSetSuccess = '/pin/success';

  static const String initialRoute = root;

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return MaterialPageRoute(builder: (_) => const RootGate());
      case splash1:
        return MaterialPageRoute(builder: (_) => const Splash1Screen());
      case splash2:
        return MaterialPageRoute(builder: (_) => const Splash2Screen());
      case splash3:
        return MaterialPageRoute(builder: (_) => const Splash3Screen());
      case splash4:
        return MaterialPageRoute(builder: (_) => const Splash4Screen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case authSuccess:
        return MaterialPageRoute(
          builder: (context) => SuccessScreen(
            onGoToLogin: () => Navigator.pushNamedAndRemoveUntil(
              context,
              login,
              (route) => false,
            ),
          ),
        );
      case forgot:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => ChatScreen());
      case bankAdd:
        return MaterialPageRoute(builder: (_) => const BankAddModalScreen());
      case bankInfo:
        return MaterialPageRoute(builder: (_) => const BankInfoScreen());
      case linkWithMobile:
        return MaterialPageRoute(builder: (_) => const LinkWithMobileScreen());
      case pinEnter:
        return MaterialPageRoute(builder: (_) => const EnterPinScreen());
      case pinCreate:
        return MaterialPageRoute(builder: (_) => const CreatePinScreen());
      case pinConfirm:
        final arg = settings.arguments;
        final createdPin = arg is String ? arg : null;
        return MaterialPageRoute(
          builder: (_) => ConfirmPinScreen(createdPin: createdPin),
        );
      case pinSetSuccess:
        return MaterialPageRoute(builder: (_) => const PinSetSuccessScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
