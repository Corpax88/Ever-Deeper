#!/usr/bin/env python3
"""Post-run plot only; never imported by the measured harness."""
import json
from pathlib import Path
import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

root = Path(sys.argv[1])
raw = json.loads((root/'success-run/mac/raw-loop.json').read_text())
analysis = json.loads((root/'success-run/mac/phase-analysis.json').read_text())
review = json.loads((root/'review.json').read_text())
starts = [x['start'] for x in raw['rows']]
durations = [x['end']-x['start'] for x in raw['rows']]
times = [(x-starts[0])/1000 for x in starts]
intervals = [b-a for a,b in zip(starts,starts[1:])]
plt.rcParams.update({'font.size': 10, 'axes.spines.top': False, 'axes.spines.right': False})
fig, (ax, phases) = plt.subplots(2, 1, figsize=(14, 6.7), height_ratios=[3, 1.5], sharex=True, layout='constrained')
ax.scatter(times[:-1], intervals, s=5, c='#1879bd', alpha=.6, label='Next callback interval', rasterized=True)
ax.scatter(times, durations, s=3, c='#444a52', alpha=.55, label='Synchronous callback wall time', rasterized=True)
ax.axhline(20, c='#a67c00', lw=.8, ls=':', label='20ms reference (not presented-frame timing)')
for row in review['large_intervals']:
    x = row['from_seconds']
    ax.scatter([x], [row['interval_ms']], s=35, c='#c93830', zorder=5)
    ax.annotate(f"{row['interval_ms']:.2f}ms interval\n{row['callback_ms']:.2f}ms callback\nNo selected owner", xy=(x, row['interval_ms']), xytext=(x+1.8, 450), fontsize=9, arrowprops={'arrowstyle': '-', 'color': '#c93830'}, color='#832820')
    phases.axvline(x, c='#c93830', lw=1, ls='--', alpha=.7)
ax.set_yscale('log')
ax.set_ylim(min(min(durations), min(intervals))*.68, 1000)
ax.set_ylabel('Milliseconds (log scale)')
ax.legend(loc='center', bbox_to_anchor=(.5, .59), ncol=3, fontsize=9)
ax.set_title('The three large callbacks occur outside synchronous rebase, generation and save spans', loc='left', pad=13, fontweight='bold')
colors = {1:'#4c8e31', 2:'#9759a6', 3:'#d48a0e'}
for span in analysis['spans']:
    phases.scatter([(span['start_ms']-raw['started'])/1000], [span['kind']], s=15+span['duration_ms']*3, c=colors[span['kind']], zorder=3)
phases.set_yticks([1,2,3], ['Generate (inside rebase)', 'Rebase', 'Save'])
phases.set_ylim(.5,3.5)
phases.set_xlim(-.2,61)
phases.set_xlabel('Seconds from the first measured engine-loop callback')
phases.grid(axis='x', alpha=.18)
phases.set_title('29 real owner events; 80.38ms interval union in 60.01644s. Clock alignment ±0.05ms.', loc='left', fontsize=10)
fig.suptitle('DEV11 diagnostic WebKit run35218778984 · 1696×780 · 3,558 callbacks', fontsize=11, x=.5)
fig.savefig(root/'hitch-owner-attribution.png', dpi=150)
