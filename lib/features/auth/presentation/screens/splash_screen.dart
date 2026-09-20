import 'package:flutter/material.dart';

/// عرض شعار التطبيق فقط؛ منطق التوجيه الفعلي يعيش في [routerProvider.redirect]
/// وليس هنا — حتى لا يتكرر منطق فحص الجلسة في أكثر من مكان (راجع بند 4 في التصميم).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(size: 96), // يُستبدل بشعار التطبيق الفعلي
      ),
    );
  }
}
