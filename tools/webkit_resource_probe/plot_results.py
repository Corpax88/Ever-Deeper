#!/usr/bin/env python3
"""Post-run figure, not part of the measured browser harness."""
import argparse
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser()
parser.add_argument('evidence', type=Path)
root = parser.parse_args().evidence
review = json.loads((root/'review.json').read_text())
raw = json.loads((root/'mac/raw-loop.json').read_text())['rows']
x = [(r['start']-raw[0]['start'])/1000 for r in raw[:-1]]
y = [raw[i+1]['start']-r['start'] for i, r in enumerate(raw[:-1])]
plt.rcParams.update({'font.size': 11, 'axes.spines.top': False, 'axes.spines.right': False})
fig, (ax, bars) = plt.subplots(2, 1, figsize=(13.6, 8.8), gridspec_kw={'height_ratios': [1, 1.05]})
fig.subplots_adjust(top=.88, bottom=.19, left=.14, right=.95, hspace=.48)
fig.suptitle('DEV11 WebKit: two hitches include long LINK_STATUS calls', x=.14, y=.965, ha='left', fontsize=17, weight='bold')
fig.text(.14, .922, 'One 60.00166 s diagnostic · unchanged original package · engine-loop cadence, not presented FPS', fontsize=11)
ax.plot(x, y, color='#8492a6', linewidth=.65, alpha=.9)
ax.axhline(20, color='#90a5b7', linewidth=.8, linestyle='--')
ax.set(xlim=(0, 60), ylim=(0, 710), ylabel='Start-to-start interval (ms)', xlabel='Seconds from first measured callback')
ax.grid(axis='y', alpha=.15)
for h, offset in zip(review['hitches'], [(3, 615), (15, 390), (33, 330)]):
    ax.scatter([h['relative_start_s']], [h['interval_ms']], s=34, color='#d97732', zorder=3)
    ax.annotate(f"{h['interval_ms']:.2f} ms", (h['relative_start_s'], h['interval_ms']), xytext=offset,
                arrowprops={'arrowstyle': '-', 'color': '#4c5866'}, fontsize=10)
series = [
    ('LINK_STATUS host call', '#d97732', lambda h: h['by_method_ms']['getProgramParameter']),
    ('COMPILE_STATUS host calls', '#8364a7', lambda h: h['by_method_ms']['getShaderParameter']),
    ('Other selected calls', '#4e8eaa', lambda h: h['selected_union_ms']-h['by_method_ms']['getProgramParameter']-h['by_method_ms']['getShaderParameter']),
    ('Outside selected calls', '#59677a', lambda h: h['outside_selected_calls_ms']),
    ('Gap after callback', '#dce2e9', lambda h: h['gap_after_callback_ms']),
]
left = [0]*len(review['hitches'])
for name, color, value in series:
    values = [value(h) for h in review['hitches']]
    bars.barh(range(3), values, left=left, color=color, height=.58, label=name)
    for i, v in enumerate(values):
        if v >= 65:
            bars.text(left[i]+v/2, i, f'{v:.2f}', ha='center', va='center', color='#172533' if name=='Gap after callback' else 'white', fontsize=10)
    left = [a+b for a, b in zip(left, values)]
bars.set_yticks(range(3), [f"{h['relative_start_s']:.5f} s\ncallback {h['callback_index']}" for h in review['hitches']])
bars.invert_yaxis()
bars.set(xlim=(0, 710), xlabel='Milliseconds within each start-to-start interval')
bars.set_title('Measured host-call wall time inside each callback; remaining work is unattributed', fontsize=11, loc='left', pad=12)
bars.grid(axis='x', alpha=.12)
bars.set_axisbelow(True)
bars.legend(loc='upper left', bbox_to_anchor=(0, -.28), ncol=3, frameon=False, fontsize=10)
fig.text(.14, .012, '181 selected calls · 0 drops/errors · 741.26 ms total selected wall time\nStatus-query waits are not exclusive GPU or compiler-only time. The third hitch has no selected calls.', fontsize=10, color='#445264')
fig.savefig(root/'hitch-host-attribution.png', dpi=125, facecolor='white')
