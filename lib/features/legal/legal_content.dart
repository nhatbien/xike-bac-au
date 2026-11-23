import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LegalContent {
  static Map<String, dynamic>? _cached;
  static Future<Map<String, dynamic>>? _loading;

  static Future<Map<String, dynamic>> get data {
    final cached = _cached;
    if (cached != null) return SynchronousFuture(cached);
    return _loading ??= rootBundle
        .loadString('assets/legal/content.json')
        .then((text) => _cached = jsonDecode(text) as Map<String, dynamic>);
  }
}
