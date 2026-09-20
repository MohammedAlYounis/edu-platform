import 'package:flutter/material.dart';

/// عرض شعار التطبيق فقط؛ منطق التوجيه الفعلي يعيش في [routerProvider.redirect]
/// وليس هنا — حتى لا يتكرر منطق فحص الجلسة في أكثر من مكان (راجع بند 4 في التصميم).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/app-icon-edu.jpeg',
          width: 96,
          height: 96,
        ),
      ),
    );
  }
}
