import os
import time

old_name = "music_tag_editor"
new_name = "music_hub"

for i in range(5):
    try:
        os.rename(old_name, new_name)
        print(f"Successfully renamed {old_name} to {new_name}")
        break
    except Exception as e:
        print(f"Attempt {i+1} failed: {e}")
        time.sleep(2)
