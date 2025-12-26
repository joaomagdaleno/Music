# Music

## Firebase Setup for Local Development

To set up your local environment for Firebase, follow these steps:

1.  **Create `google-services.json`:**
    *   Navigate to `music_tag_editor/android/app/`.
    *   Copy `google-services.json.template` and rename it to `google-services.json`.
    *   Replace the placeholder values in `google-services.json` with your actual Firebase project's configuration. You can download this file from the Firebase console.

2.  **Create `firebase_options.dart`:**
    *   Navigate to `music_tag_editor/lib/`.
    *   Copy `firebase_options.dart.template` and rename it to `firebase_options.dart`.
    *   Replace the placeholder values in `firebase_options.dart` with your actual Firebase project's configuration. You can get this from the Firebase console.
