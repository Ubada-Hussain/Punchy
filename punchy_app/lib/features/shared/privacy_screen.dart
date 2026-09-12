import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Privacy & Security'), backgroundColor: AppColors.bg, elevation: 0),
    body: ListView(padding: const EdgeInsets.all(22), children: const [
      Text('Your privacy matters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      SizedBox(height: 12), Text('Punchy uses your account, loyalty-card and punch information to provide the app features you request. Data is transmitted over encrypted HTTPS connections and is not sold.'),
      SizedBox(height: 22), Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 8), Text('We use secure authentication, protected storage and access controls to safeguard your account. You can disable push notifications in Settings.'),
      SizedBox(height: 22), Text('Your choices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 8), Text('You can update your profile, manage notifications, or request account deletion after email verification.'),
      SizedBox(height: 22), Text('Full policy: trypunchy.site/privacy-policy'),
    ]),
  );
}
