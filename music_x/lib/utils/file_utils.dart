import 'package:path/path.dart' as p;

/// Shared utility for filename sanitization to prevent path traversal
/// and ensure cross-platform compatibility.
String sanitizeFilename(String filename) {
  // Replace slashes first to preserve segments if they were intended as part of the filename
  // (e.g. "AC/DC.flac") while still preventing them from being interpreted as paths.
  final sanitizedPath = filename.replaceAll(RegExp(r'[\\/]'), '_');

  // Use basename as a safety measure against any lingering path traversal attempts
  final base = p.basename(sanitizedPath);

  // Replace other characters that are reserved/illegal on various OS:
  // : * ? " < > |
  return base.replaceAll(RegExp(r'[:*?"<>|]'), '_');
}
