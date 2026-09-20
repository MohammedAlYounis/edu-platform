import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension LocalizationX on BuildContext {
  String t(String key) => AppLocalizations.of(this).t(key);
  bool get isRtl => AppLocalizations.of(this).isRtl;
}
