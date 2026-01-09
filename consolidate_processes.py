import os
import datetime

def consolidate_processes():
    root_to_scan = '.'  # Scan from root to capture .github, scripts, etc.
    music_x_root = 'music_x'
    output_dir = 'projeto music'
    
    # Ensure output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Process Mappings
    processes = {
        'processo_login_seguranca.txt': [
            r'music_x/lib/core/services/auth_service.dart',
            r'music_x/lib/core/services/security_service.dart',
            r'music_x/lib/features/security',
            r'music_x/lib/firebase_options.dart',
            r'music_x/android/app/google-services.json'
        ],
        'processo_busca_discovery.txt': [
            r'music_x/lib/features/discovery',
            r'music_x/lib/api'
        ],
        'processo_download.txt': [
            r'music_x/lib/core/services/dependency_manager.dart',
            r'music_x/lib/core/services/hifi_download_service.dart',
            r'music_x/lib/features/discovery/services/download'
        ],
        'processo_biblioteca.txt': [
            r'music_x/lib/features/library',
            r'music_x/lib/core/services/database',
            r'music_x/lib/core/services/music_manager_service.dart',
            r'music_x/lib/core/services/smart_playlist_service.dart',
            r'music_x/lib/core/services/duplicate_detector_service.dart'
        ],
        'processo_player.txt': [
            r'music_x/lib/features/player',
            r'music_x/lib/core/services/hifi_audio_service.dart',
            r'music_x/lib/core/services/cast_service.dart',
            r'music_x/lib/features/party_mode'
        ],
        'processo_frontend_shared.txt': [
            r'music_x/lib/features/home',
            r'music_x/lib/core/widgets',
            r'music_x/lib/core/services/theme',
            r'music_x/lib/core/services/notification',
            r'music_x/lib/core/services/global_navigation_service.dart'
        ],
        'processo_cicd_build.txt': [
            r'.github',
            r'scripts',
            r'music_x/android',
            r'music_x/ios',
            r'music_x/windows',
            r'music_x/linux',
            r'music_x/pubspec.yaml',
            r'music_x/analysis_options.yaml',
            r'README.md',
            r'installer.iss',
            r'.lefthook.yml'
        ],
        'processo_core_infra.txt': [
            r'music_x/lib/main.dart',
            r'music_x/lib/core/services/startup',
            r'music_x/lib/core/services/telemetry',
            r'music_x/lib/core/services/firebase_sync',
            r'music_x/lib/utils',
            r'music_x/lib/config',
            r'music_x/lib/core/services/connectivity_service.dart',
            r'music_x/lib/core/services/local_duo_service.dart'
        ],
        'processo_testes.txt': [
           r'music_x/test',
           r'music_x/integration_test'
        ],
        'processo_outros.txt': [] # Catch-all
    }

    extensions = ('.kt', '.kts', '.java', '.xml', '.gradle', '.properties', '.yml', '.yaml', '.md', '.sh', '.ps1', '.dart', '.json', '.cc', '.cpp', '.h', '.rc', '.cmake', '.iss')
    exclude_dirs_names = {'.git', 'build', '.gradle', 'node_modules', '.idea', '.vscode', '.dart_tool', 'debug', 'release', 'profile'}
    
    # Store file content buffers to avoid opening/closing files constantly? 
    # Actually, better to map files to buckets first, then write.
    file_buckets = {k: [] for k in processes.keys()}

    start_time = datetime.datetime.now()
    total_files = 0
    
    print(f"Scanning files in {os.getcwd()}...")

    for root, dirs, files in os.walk(root_to_scan):
        dirs[:] = [d for d in dirs if d not in exclude_dirs_names]
        
        for file in files:
            if file.endswith(extensions):
                file_path = os.path.join(root, file)
                # Normalize path for matching (forward slashes)
                rel_path = os.path.relpath(file_path, root_to_scan).replace('\\', '/')
                
                # Skip the output folder and script itself
                if rel_path.startswith('projeto music/') or rel_path == 'consolidate_processes.py' or rel_path == 'codigo_projeto_music.txt' or rel_path == 'consolidate_music.py':
                    continue
                
                # Determine bucket
                assigned_bucket = 'processo_outros.txt'
                
                # Order matters? Specificity matters.
                # Check specifics first.
                for bucket, patterns in processes.items():
                    if bucket == 'processo_outros.txt': continue
                    for pattern in patterns:
                        # Check if path contains pattern or matches starts with
                        if rel_path.startswith(pattern) or pattern in rel_path:
                            assigned_bucket = bucket
                            break
                    if assigned_bucket != 'processo_outros.txt':
                        break
                
                file_buckets[assigned_bucket].append(file_path)
                total_files += 1

    print(f"Assigning {total_files} files to buckets...")
    
    for bucket_name, files_list in file_buckets.items():
        output_path = os.path.join(output_dir, bucket_name)
        with open(output_path, 'w', encoding='utf-8') as outfile:
            outfile.write("="*80 + "\n")
            outfile.write(f"PROCESS AUDIT: {bucket_name}\n")
            outfile.write(f"DATE: {start_time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            outfile.write(f"FILE COUNT: {len(files_list)}\n")
            outfile.write("="*80 + "\n\n")
            
            for file_path in sorted(files_list):
                 rel_path = os.path.relpath(file_path, root_to_scan)
                 outfile.write(f"{'-'*10} FILE: {rel_path} {'-'*10}\n")
                 try:
                    try:
                        with open(file_path, 'r', encoding='utf-8') as infile:
                             content = infile.read()
                    except UnicodeDecodeError:
                        with open(file_path, 'r', encoding='latin-1') as infile:
                             content = infile.read()
                    outfile.write(content)
                 except Exception as e:
                    outfile.write(f"ERROR READING FILE: {e}\n")
                 outfile.write("\n\n")

    end_time = datetime.datetime.now()
    print(f"Consolidation complete. Duration: {end_time - start_time}")

if __name__ == "__main__":
    consolidate_processes()
