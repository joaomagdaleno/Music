import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MusicTagEditorApp());
}
