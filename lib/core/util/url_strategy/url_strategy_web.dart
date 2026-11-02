import 'package:flutter_web_plugins/url_strategy.dart';

/// Web implementation using HTML5 path URL strategy (clean URLs without #).
void configureUrlStrategy() {
  usePathUrlStrategy();
}
