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
        (r'package:music_hub/services/backup_service\.dart', r'package:music_hub/core/services/backup_service.dart'),
        (r'package:music_hub/services/cast_service\.dart', r'package:music_hub/core/services/cast_service.dart'),
        
        (r'package:music_hub/widgets/', r'package:music_hub/core/widgets/'),
        (r'package:music_hub/models/', r'package:music_hub/features/library/models/'),
        (r'package:music_hub/services/', r'package:music_hub/core/services/'),
        
        # General patterns for features
        (r'package:music_hub/screens/library/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/screens/player/', r'package:music_hub/features/player/screens/'),
        (r'package:music_hub/screens/edit/', r'package:music_hub/features/library/screens/'),
        (r'package:music_hub/screens/home/', r'package:music_hub/features/home/'),
        (r'package:music_hub/screens/settings/', r'package:music_hub/features/settings/screens/'),
        
        # Discovery specific
        (r'package:music_hub/services/search/', r'package:music_hub/features/discovery/services/search/'),
        (r'package:music_hub/services/download/', r'package:music_hub/features/discovery/services/download/'),
        (r'package:music_hub/screens/search/', r'package:music_hub/features/discovery/screens/'),
        (r'SearchScreen', r'DiscoveryScreen'),
        (r'package:music_hub/features/discovery/screens/search_screen\.dart', r'package:music_hub/features/discovery/screens/discovery_screen.dart'),
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
