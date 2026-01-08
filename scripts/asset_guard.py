import os
import re
import sys

def get_unused_assets():
    project_root = "music_x"
    assets_dir = os.path.join(project_root, "assets")
    lib_dir = os.path.join(project_root, "lib")
    
    if not os.path.exists(assets_dir):
        print("ℹ️ No assets directory found.")
        return []

    # Get all files in assets directory
    asset_files = []
    for root, _, files in os.walk(assets_dir):
        for file in files:
            # We want the path relative to the assets folder or the full path used in code
            # Usually it's 'assets/...'
            rel_path = os.relpath(os.path.join(root, file), project_root).replace("\\", "/")
            asset_files.append(rel_path)

    if not asset_files:
        print("✅ No assets found to audit.")
        return []

    # Search for asset strings in lib directory
    unused_assets = set(asset_files)
    
    # Also check pubspec.yaml for explicitly listed assets if any (though usually it's just the folder)
    pubspec_path = os.path.join(project_root, "pubspec.yaml")
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        pubspec_content = f.read()
        for asset in list(unused_assets):
            if asset in pubspec_content:
                unused_assets.discard(asset)

    # Scan Dart files
    for root, _, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                with open(os.path.join(root, file), 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    for asset in list(unused_assets):
                        # Match the asset path in strings
                        if f'"{asset}"' in content or f"'{asset}'" in content or asset.split('/')[-1] in content:
                            unused_assets.discard(asset)

    return sorted(list(unused_assets))

if __name__ == "__main__":
    print("🧪 Hermes: The Alchemist's Brew - Asset Audit")
    unused = get_unused_assets()
    
    if unused:
        print(f"⚠️ Found {len(unused)} potentially unused assets:")
        for a in unused:
            print(f"  - {a}")
        # We don't fail yet, just report
        sys.exit(0) 
    else:
        print("✅ All assets appear to be in use.")
        sys.exit(0)
