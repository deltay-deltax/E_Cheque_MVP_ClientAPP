import 'package:flutter/material.dart';

class L10n {
  L10n._();

  static const supportedLocales = [
    Locale('en'),
    Locale('kn'),
    Locale('hi'),
  ];

  static const localeNames = {
    'en': 'English',
    'kn': 'Kannada',
    'hi': 'Hindi',
  };

  static const _en = {
    'app_name': 'E-Cheque MVP',
    'profile': 'Profile',
    'account_settings': 'Account Settings',
    'personal_information': 'Personal Information',
    'personal_information_sub': 'Update your personal details',
    'security_settings': 'Security Settings',
    'notification_preferences': 'Notification Preferences',
    'notification_preferences_sub': 'Customize your alerts',
    'language': 'Language',
    'language_sub': 'Choose your preferred language',
    'financial_tools': 'Financial Tools',
    'support_and_help': 'Support and Help',
    'budget_planner': 'Budget Planner',
    'budget_planner_sub': 'Track your spending',
    'currency_converter': 'Currency Converter',
    'currency_converter_sub': 'Check exchange rates',
    'bill_payment': 'Bill Payment',
    'bill_payment_sub': 'Pay your bills easily',
    'tax_calculator': 'Tax Calculator',
    'tax_calculator_sub': 'Estimate your taxes',
    'auto_fill_forms': 'Auto Fill Forms',
    'auto_fill_forms_sub': 'Speed up your applications',
    'contact_us': 'Contact Us',
    'privacy_policy': 'Privacy Policy',
    'logout': 'Logout',
    'choose_language': 'Choose Language',
    'english': 'English',
    'kannada': 'Kannada',
    'hindi': 'Hindi',
  };

  static const _kn = {
    'app_name': 'ಇ-ಚೆಕ್ ಎಂವಿಪಿ',
    'profile': 'ಪ್ರೊಫೈಲ್',
    'account_settings': 'ಖಾತೆ ಸಂಯೋಜನೆಗಳು',
    'personal_information': 'ವೈಯಕ್ತಿಕ ಮಾಹಿತಿ',
    'personal_information_sub': 'ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ವಿವರಗಳನ್ನು ನವೀಕರಿಸಿ',
    'security_settings': 'ಭದ್ರತಾ ಸಂಯೋಜನೆಗಳು',
    'notification_preferences': 'ಸೂಚನೆ ಆಯ್ಕೆಗಳು',
    'notification_preferences_sub': 'ನಿಮ್ಮ ಎಚ್ಚರಿಕೆಗಳನ್ನು ಕಸ್ಟಮೈಸ್ ಮಾಡಿ',
    'language': 'ಭಾಷೆ',
    'language_sub': 'ನಿಮ್ಮ ಇಷ್ಟದ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'financial_tools': 'ಹಣಕಾಸು ಉಪಕರಣಗಳು',
    'support_and_help': 'ಬೆಂಬಲ ಮತ್ತು ಸಹಾಯ',
    'budget_planner': 'ಬಜೆಟ್ ಯೋಜಕ',
    'budget_planner_sub': 'ನಿಮ್ಮ ಖರ್ಚನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ',
    'currency_converter': 'ಕರೆನ್ಸಿ ಪರಿವರ್ತಕ',
    'currency_converter_sub': 'ವಿನಿಮಯ ದರಗಳನ್ನು ಪರಿಶೀಲಿಸಿ',
    'bill_payment': 'ಬಿಲ್ ಪಾವತಿ',
    'bill_payment_sub': 'ನಿಮ್ಮ ಬಿಲ್ಲುಗಳನ್ನು ಸುಲಭವಾಗಿ ಪಾವತಿಸಿ',
    'tax_calculator': 'ತೆರಿಗೆ ಕ್ಯಾಲ್ಕ್ಯುಲೇಟರ್',
    'tax_calculator_sub': 'ನಿಮ್ಮ ತೆರಿಗೆಯನ್ನು ಅಂದಾಜಿಸಿ',
    'auto_fill_forms': 'ಸ್ವಯಂ ಭರ್ತಿ ಫಾರ್ಮ್‌ಗಳು',
    'auto_fill_forms_sub': 'ನಿಮ್ಮ ಅರ್ಜಿಗಳನ್ನು ವೇಗಗೊಳಿಸಿ',
    'contact_us': 'ನಮ್ಮನ್ನು ಸಂಪರ್ಕಿಸಿ',
    'privacy_policy': 'ಗೌಪ್ಯತಾ ನೀತಿ',
    'logout': 'ಲಾಗ್‌ಔಟ್',
    'choose_language': 'ಭಾಷೆಯನ್ನು ಆರಿಸಿ',
    'english': 'ಇಂಗ್ಲಿಷ್',
    'kannada': 'ಕನ್ನಡ',
    'hindi': 'ಹಿಂದಿ',
  };

  static const _hi = {
    'app_name': 'ई-चेक एमवीपी',
    'profile': 'प्रोफ़ाइल',
    'account_settings': 'खाता सेटिंग्स',
    'personal_information': 'व्यक्तिगत जानकारी',
    'personal_information_sub': 'अपनी व्यक्तिगत जानकारी अपडेट करें',
    'security_settings': 'सुरक्षा सेटिंग्स',
    'notification_preferences': 'सूचना वरीयताएँ',
    'notification_preferences_sub': 'अपने अलर्ट अनुकूलित करें',
    'language': 'भाषा',
    'language_sub': 'अपनी पसंदीदा भाषा चुनें',
    'financial_tools': 'वित्तीय उपकरण',
    'support_and_help': 'समर्थन और सहायता',
    'budget_planner': 'बजट योजनाकार',
    'budget_planner_sub': 'अपने खर्च का ट्रैक रखें',
    'currency_converter': 'मुद्रा परिवर्तक',
    'currency_converter_sub': 'विनिमय दरें देखें',
    'bill_payment': 'बिल भुगतान',
    'bill_payment_sub': 'अपने बिल आसानी से भरें',
    'tax_calculator': 'कर कैलकुलेटर',
    'tax_calculator_sub': 'अपने कर का अनुमान लगाएं',
    'auto_fill_forms': 'ऑटो फिल फॉर्म्स',
    'auto_fill_forms_sub': 'अपनी एप्लिकेशन तेज़ करें',
    'contact_us': 'हमसे संपर्क करें',
    'privacy_policy': 'गोपनीयता नीति',
    'logout': 'लॉगआउट',
    'choose_language': 'भाषा चुनें',
    'english': 'अंग्रेज़ी',
    'kannada': 'कन्नड़',
    'hindi': 'हिंदी',
  };

  static Map<String, String> _mapFor(String code) {
    switch (code) {
      case 'kn':
        return _kn;
      case 'hi':
        return _hi;
      case 'en':
      default:
        return _en;
    }
  }

  static String tr(String code, String key) {
    final m = _mapFor(code);
    return m[key] ?? _en[key] ?? key;
  }
}
