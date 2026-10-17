import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('Intl.DateTimeFormat')
external _DateFormatter _dateFormatter();
extension type _DateFormatter(JSObject _) implements JSObject {
  external _DateOptions resolvedOptions();
}
extension type _DateOptions(JSObject _) implements JSObject {
  external String get timeZone;
}
String browserTimezone() => _dateFormatter().resolvedOptions().timeZone;
bool browserHidden() => web.document.hidden;
