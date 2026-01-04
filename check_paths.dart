import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  print('APPDATA: ${Platform.environment['APPDATA']}');
  print('LOCALAPPDATA: ${Platform.environment['LOCALAPPDATA']}');
  print('USERPROFILE: ${Platform.environment['USERPROFILE']}');
  
  final appData = Platform.environment['APPDATA']!;
  final binDir = p.join(appData, 'music_tag_editor');
  print('Target Bin Dir: $binDir');
  
  // path_provider simulation (roughly)
  final appSupport = p.join(appData, 'com.example', 'music_tag_editor'); // Default for many flutter apps if not set
  print('Estimated App Support Dir: $appSupport');
}
