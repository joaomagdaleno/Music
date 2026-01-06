import 'package:path/path.dart' as p;

/// Shared utility for filename sanitization to prevent path traversal
/// and ensure cross-platform compatibility.
String sanitizeFilename(String filename) {
  // Use basename to prevent directory traversal
  final base = p.basename(filename);
  
  // Replace characters that are reserved/illegal on various OS:
  // / \ : * ? " < > |
  return base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}
