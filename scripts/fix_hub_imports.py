import os
import re

def fix_imports(directory):
    replacements = [
        (r'package:music_hub/services/auth_service\.dart', r'package:music_hub/core/services/auth_service.dart'),
        (r'package:music_hub/services/database_service\.dart', r'package:music_hub/core/services/database_service.dart'),
        (r'package:music_hub/services/dependency_manager\.dart', r'package:music_hub/core/services/dependency_manager.dart'),
        (r'package:music_hub/services/connectivity_service\.dart', r'package:music_hub/core/services/connectivity_service.dart'),
        (r'package:music_hub/services/desktop_integration_service\.dart', r'package:music_hub/core/services/desktop_integration_service.dart'),
        (r'package:music_hub/services/security_service\.dart', r'package:music_hub/core/services/security_service.dart'),
        (r'package:music_hub/services/startup_logger\.dart', r'package:music_hub/core/services/startup_logger.dart'),
        (r'package:music_hub/services/telemetry_service\.dart', r'package:music_hub/core/services/telemetry_service.dart'),
        (r'package:music_hub/services/theme_service\.dart', r'package:music_hub/core/services/theme_service.dart'),
        (r'package:music_hub/services/notification_service\.dart', r'package:music_hub/core/services/notification_service.dart'),
        (r'package:music_hub/services/music_manager_service\.dart', r'package:music_hub/core/services/music_manager_service.dart'),
        # Sub-view mappings
        (r'package:music_hub/screens/playlists/views/', r'package:music_hub/features/library/playlists/views/'),
        (r'package:music_hub/screens/playlists/', r'package:music_hub/features/library/playlists/'),
        (r'package:music_hub/screens/stats/views/', r'package:music_hub/features/library/stats/views/'),
        (r'package:music_hub/screens/stats/', r'package:music_hub/features/library/stats/'),
        (r'package:music_hub/screens/backup/', r'package:music_hub/features/library/backup/'),
        (r'package:music_hub/screens/login/views/', r'package:music_hub/features/core/login/views/'),
        (r'package:music_hub/screens/login/', r'package:music_hub/features/core/login/'),
        
        # Features screens/views
        (r'package:music_hub/features/party_mode/views/', r'package:music_hub/features/party_mode/disco/views/'),
        (r'package:music_hub/features/party_mode/(\w+)_screen\.dart', r'package:music_hub/features/party_mode/disco/\1_screen.dart'),
        (r'package:music_hub/features/security/views/', r'package:music_hub/features/security/vault/views/'),
        (r'package:music_hub/features/security/(\w+)_screen\.dart', r'package:music_hub/features/security/vault/\1_screen.dart'),
        
        # Library views
        (r'package:music_hub/features/library/screens/views/', r'package:music_hub/features/library/screens/views/'),
        
        # Discovery
        (r'package:music_hub/features/discovery/screens/views/', r'package:music_hub/features/discovery/screens/views/'),
        
        # General patterns for features (fallback)
        (r'package:music_hub/screens/library/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/screens/player/', r'package:music_hub/features/player/screens/'),
        (r'package:music_hub/screens/edit/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/screens/home/', r'package:music_hub/features/home/'),
        (r'package:music_hub/screens/settings/views/', r'package:music_hub/features/settings/screens/views/'),
        (r'package:music_hub/screens/settings/', r'package:music_hub/features/settings/screens/'),
        
        # Discovery specific
        (r'package:music_hub/services/search/', r'package:music_hub/features/discovery/services/search/'),
        (r'package:music_hub/services/download/', r'package:music_hub/features/discovery/services/download/'),
        (r'package:music_hub/screens/search/', r'package:music_hub/features/discovery/screens/'),
        (r'SearchScreen', r'DiscoveryScreen'),
        (r'package:music_hub/features/discovery/screens/search_screen\.dart', r'package:music_hub/features/discovery/screens/discovery_screen.dart'),
        (r'package:music_hub/views/app_shell\.dart', r'package:music_hub/features/core/screens/app_shell.dart'),
    ]

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content
                for pattern, replacement in replacements:
                    new_content = re.sub(pattern, replacement, new_content)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed: {filepath}")

if __name__ == "__main__":
    fix_imports('music_hub/lib')
    fix_imports('music_hub/test')
