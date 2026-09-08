"""Deterministic review timeline; runtime wall targeting is not implemented."""
import math
def smooth(x):
    x=max(0,min(1,x));return x*x*(3-2*x)
def blink_at(t,start):
    q=t-start
    if q<0 or q>.20:return 0.
    if q<.065:return smooth(q/.065)
    if q<.095:return 1.
    return 1-smooth((q-.095)/.105)
def sample(t):
    phase=(t/1.45)%1
    focus=smooth(phase/.39)*(1-smooth((phase-.60)/.28))*.72
    squint=.22*smooth((phase-.52)/.035)*(1-smooth((phase-.59)/.10))
    blink=max(blink_at(t,.40),blink_at(t,3.13),squint)
    # Tiny shared pupil/glint movement; gaze remains inside both eye openings.
    gaze_x=.22*math.sin(t*math.tau/3.1)*(1-focus)
    gaze_down=.20+.65*focus
    return {'blink':blink,'focus':focus,'gaze_x':gaze_x,'gaze_down':gaze_down}
