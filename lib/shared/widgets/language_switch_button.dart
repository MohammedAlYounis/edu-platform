import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/locale_controller.dart';

class LanguageSwitchButton extends ConsumerWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final nextLanguage = locale.languageCode == 'en' ? 'العربية' : 'English';

    return IconButton(
      tooltip: nextLanguage,
      icon: const Icon(Icons.translate),
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
    );
  }
}
