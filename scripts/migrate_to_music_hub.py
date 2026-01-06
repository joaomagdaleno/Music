import os
import re

def migrate_files(directory):
    replacements = [
        (r'package:music_tag_editor/', r'package:music_hub/'),
        # Core Services
        (r'package:music_hub/services/database_service.dart', r'package:music_hub/core/services/database_service.dart'),
        (r'package:music_hub/services/theme_service.dart', r'package:music_hub/core/services/theme_service.dart'),
        (r'package:music_hub/services/startup_logger.dart', r'package:music_hub/core/services/startup_logger.dart'),
        (r'package:music_hub/services/dependency_manager.dart', r'package:music_hub/core/services/dependency_manager.dart'),
        (r'package:music_hub/services/notification_service.dart', r'package:music_hub/core/services/notification_service.dart'),
        (r'package:music_hub/services/connectivity_service.dart', r'package:music_hub/core/services/connectivity_service.dart'),
        (r'package:music_hub/services/global_navigation_service.dart', r'package:music_hub/core/services/global_navigation_service.dart'),
        (r'package:music_hub/services/database/', r'package:music_hub/core/services/database/'),
        
        # Core Widgets
        (r'package:music_hub/widgets/mini_player.dart', r'package:music_hub/core/widgets/mini_player.dart'),
        (r'package:music_hub/widgets/floating_mini_player.dart', r'package:music_hub/core/widgets/floating_mini_player.dart'),
        (r'package:music_hub/widgets/cast_dialog.dart', r'package:music_hub/core/widgets/cast_dialog.dart'),
        
        # Player
        (r'package:music_hub/services/playback_service.dart', r'package:music_hub/features/player/services/playback_service.dart'),
        (r'package:music_hub/services/lyrics_service.dart', r'package:music_hub/features/player/services/lyrics_service.dart'),
        (r'package:music_hub/services/equalizer_service.dart', r'package:music_hub/features/player/services/equalizer_service.dart'),
        (r'package:music_hub/screens/player/', r'package:music_hub/features/player/screens/'),
        (r'package:music_hub/widgets/visualizer_widget.dart', r'package:music_hub/features/player/widgets/visualizer_widget.dart'),
        (r'package:music_hub/widgets/queue_sheet.dart', r'package:music_hub/features/player/widgets/queue_sheet.dart'),
        (r'package:music_hub/widgets/interactive_equalizer_widget.dart', r'package:music_hub/features/player/widgets/interactive_equalizer_widget.dart'),
        
        # Library
        (r'package:music_hub/services/metadata_service.dart', r'package:music_hub/features/library/services/metadata_service.dart'),
        (r'package:music_hub/services/metadata_aggregator_service.dart', r'package:music_hub/features/library/services/metadata_aggregator_service.dart'),
        (r'package:music_hub/services/metadata_cleanup_service.dart', r'package:music_hub/features/library/services/metadata_cleanup_service.dart'),
        (r'package:music_hub/services/auto_tag_service.dart', r'package:music_hub/features/library/services/auto_tag_service.dart'),
        (r'package:music_hub/screens/library/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/screens/tracks/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/screens/edit/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/models/music_track.dart', r'package:music_hub/features/library/models/music_track.dart'),
        (r'package:music_hub/models/metadata_models.dart', r'package:music_hub/features/library/models/metadata_models.dart'),
        (r'package:music_hub/models/database_models.dart', r'package:music_hub/features/library/models/database_models.dart'),
        
        # Discovery
        (r'package:music_hub/services/search_service.dart', r'package:music_hub/features/discovery/services/search_service.dart'),
        (r'package:music_hub/services/download_service.dart', r'package:music_hub/features/discovery/services/download_service.dart'),
        (r'package:music_hub/services/offline_download_service.dart', r'package:music_hub/features/discovery/services/offline_download_service.dart'),
        (r'package:music_hub/services/youtube_streamer_service.dart', r'package:music_hub/features/discovery/services/youtube_streamer_service.dart'),
        (r'package:music_hub/services/search/', r'package:music_hub/features/discovery/services/search/'),
        (r'package:music_hub/services/download/', r'package:music_hub/features/discovery/services/download/'),
        (r'package:music_hub/screens/search/', r'package:music_hub/features/discovery/screens/'),
        
        # Extras
        (r'package:music_hub/screens/disco/', r'package:music_hub/features/party_mode/'),
        (r'package:music_hub/screens/vault/', r'package:music_hub/features/security/'),
    ]

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content
                for pattern, replacement in replacements:
                    new_content = new_content.replace(pattern, replacement)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated: {filepath}")

if __name__ == "__main__":
    # Note: Running from root, adjust if needed
    migrate_files('music_tag_editor/lib')
    migrate_files('music_tag_editor/test')
