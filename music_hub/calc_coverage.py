import re
import os

lf = 0
lh = 0
lcov_path = 'coverage/lcov.info'

if os.path.exists(lcov_path):
    with open(lcov_path, 'r') as f:
        for line in f:
            m_lf = re.search(r'LF:(\d+)', line)
            if m_lf:
                lf += int(m_lf.group(1))
            m_lh = re.search(r'LH:(\d+)', line)
            if m_lh:
                lh += int(m_lh.group(1))
    if lf > 0:
        print(f"LF: {lf}, LH: {lh}, Coverage: {round(lh/lf*100, 2)}%")
    else:
        print("No lines found in lcov.info")
else:
    print("lcov.info not found")
