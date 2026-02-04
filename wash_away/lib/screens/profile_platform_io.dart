// Used when dart:io is available (mobile/desktop).

import 'dart:io' show Platform;

bool get isIOS => Platform.isIOS;
bool get isAndroid => Platform.isAndroid;
