import os
import datetime

def consolidate():
    # Only scan music_x directory as it is the project root
    root_to_scan = 'music_x'
    extensions = ('.kt', '.kts', '.java', '.xml', '.gradle', '.properties', '.yml', '.yaml', '.md', '.sh', '.ps1', '.dart')
    exclude_dirs = ('.git', 'build', '.gradle', 'node_modules', '.idea', '.vscode', '.dart_tool', 'android', 'ios', 'windows', 'linux', 'macos', 'web')
    
    # We want to include platform folders but not their build artifacts.
    # exclude_dirs above has 'android', 'ios', etc. which might be too aggressive if we want source code from them.
    # Let's adjust exclusions to be standard build folders.
    exclude_dirs_names = {'.git', 'build', '.gradle', 'node_modules', '.idea', '.vscode', '.dart_tool'}

    output_name = 'codigo_projeto_music.txt'
    output_path = os.path.join('projeto music', output_name) # Target existing file in subfolder
    
    start_time = datetime.datetime.now()
    file_count = 0
    
    print(f"Starting consolidation of {root_to_scan}...")
    
    with open(output_path, 'w', encoding='utf-8') as outfile:
        outfile.write("="*80 + "\n")
        outfile.write(f"PROJECT CONSOLIDATION REPORT: MUSIC (music_x)\n")
        outfile.write(f"DATE: {start_time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        outfile.write("="*80 + "\n\n")
        
        for root, dirs, files in os.walk(root_to_scan):
            # Modify dirs in-place to skip excluded directories
            dirs[:] = [d for d in dirs if d not in exclude_dirs_names]
            
            for file in files:
                if file.endswith(extensions):
                    file_path = os.path.join(root, file)
                    
                    rel_path = os.path.relpath(file_path, '.')
                    outfile.write(f"{'-'*10} FILE: {rel_path} {'-'*10}\n")
                    
                    try:
                        # Try UTF-8 first, then Latin-1 as fallback
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
                    file_count += 1
                    
        end_time = datetime.datetime.now()
        duration = end_time - start_time
        
        outfile.write("="*80 + "\n")
        outfile.write(f"CONSOLIDATION COMPLETE\n")
        outfile.write(f"FILES PROCESSED: {file_count}\n")
        outfile.write(f"DURATION: {duration}\n")
        outfile.write("="*80 + "\n")
        
    print(f"Consolidation complete: {output_path}")
    print(f"Processed {file_count} files in {duration}")

if __name__ == "__main__":
    consolidate()
