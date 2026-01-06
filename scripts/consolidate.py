import os

def consolidate():
    extensions = ('.dart', '.py', '.yml', '.yaml', '.iss')
    exclude_dirs = ('node_modules', '.git', 'build')
    output_path = os.path.join('projeto music', 'codigo_projeto_music.txt')
    
    if not os.path.exists('projeto music'):
        os.makedirs('projeto music')
        
    with open(output_path, 'w', encoding='utf-8') as outfile:
        outfile.write("--- CONSOLIDATED PROJECT CODE (STAGE 8) ---\n\n")
        for root, dirs, files in os.walk('.'):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith(extensions):
                    file_path = os.path.join(root, file)
                    outfile.write(f"--- FILE: {os.path.abspath(file_path)} ---\n")
                    try:
                        with open(file_path, 'r', encoding='utf-8') as infile:
                            outfile.write(infile.read())
                    except Exception as e:
                        outfile.write(f"Error reading file: {e}\n")
                    outfile.write("\n\n")
                    
    print(f"Consolidation complete: {output_path}")

if __name__ == "__main__":
    consolidate()
