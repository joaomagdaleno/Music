import os

def remove_persona_logic(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Remove import
                new_content = content.replace("import 'package:music_hub/core/services/persona_service.dart';", "")
                
                # Remove subtitle line with Persona
                import re
                new_content = re.sub(r"subtitle: Text\(\s*'Perfil: \${PersonaService\.instance\.currentPersona\.name}',\s*\),", "// Persona info removed", new_content)
                new_content = re.sub(r"subtitle: Text\(\s*'Perfil: ' \+ PersonaService\.instance\.currentPersona\.name,\s*\),", "// Persona info removed", new_content)

                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Removed Persona from: {filepath}")

if __name__ == "__main__":
    remove_persona_logic('music_hub/lib')
