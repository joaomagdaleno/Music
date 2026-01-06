import os

def update_workflows(directory, old_name, new_name):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.yml') or file.endswith('.yaml') or file.endswith('.iss'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Careful not to replace substrings if not intended, 
                # but here it's usually safe to replace music_tag_editor with music_hub
                new_content = content.replace(old_name, new_name)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Updated: {filepath}")

if __name__ == "__main__":
    update_workflows('.github/workflows', 'music_tag_editor', 'music_hub')
    update_workflows('.', 'music_tag_editor', 'music_hub') # Covers installer.iss and lefthook
