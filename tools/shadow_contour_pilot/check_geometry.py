"""Independently compare emitted contour segments to the exact grid boundary.

Also compare first intersections from air to original rectangle/contour edges.
The emitted polygon data comes from the actual GDScript candidate, not a Python
reimplementation of its tracing algorithm.
"""
import argparse
from collections import Counter
import json
import math
from pathlib import Path


def segments(polygons):
    return [(a, b) for p in polygons for a, b in zip(p, p[1:] + p[:1])]


def boundary_edges(cells):
    found = Counter()
    for x, y in cells:
        corners = [(x, y), (x+1, y), (x+1, y+1), (x, y+1)]
        for a, b in zip(corners, corners[1:]+corners[:1]):
            found[tuple(sorted((a,b)))] += 1
    return {edge for edge, count in found.items() if count == 1}


def polygon_edges(polygons, tile=64):
    found = Counter()
    for a, b in segments(polygons):
        a = tuple(v/tile for v in a)
        b = tuple(v/tile for v in b)
        assert all(v.is_integer() for v in a+b), (a,b)
        assert (a[0] == b[0]) != (a[1] == b[1]), (a,b)
        length = int(abs(b[0]-a[0])+abs(b[1]-a[1]))
        d = ((b[0]-a[0])/length, (b[1]-a[1])/length)
        for n in range(length):
            p = (a[0]+n*d[0], a[1]+n*d[1])
            q = (p[0]+d[0], p[1]+d[1])
            found[tuple(sorted((p,q)))] += 1
    assert all(count == 1 for count in found.values()), "Duplicate boundary"
    return set(found)


def ray_first(origin, direction, edges):
    best = math.inf
    for a, b in edges:
        sx, sy = b[0]-a[0], b[1]-a[1]
        den = direction[0]*sy-direction[1]*sx
        if abs(den) < 1e-12:
            continue
        ox, oy = a[0]-origin[0], a[1]-origin[1]
        t = (ox*sy-oy*sx)/den
        u = (ox*direction[1]-oy*direction[0])/den
        if t >= 0 and -1e-10 <= u <= 1+1e-10:
            best = min(best,t)
    return best


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('input',type=Path)
    args = parser.parse_args()
    data = json.loads(args.input.read_text())
    rays = 0
    for case in data['cases']:
        cells = {tuple(c) for c in case['cells']}
        assert all(len({tuple(v) for v in poly}) == len(poly) for poly in case['polygons']), 'Self-touching polygon'
        assert polygon_edges(case['polygons']) == boundary_edges(cells), case['mask']
        rectangles = [[(x*64,y*64),((x+1)*64,y*64),((x+1)*64,(y+1)*64),(x*64,(y+1)*64)] for x,y in cells]
        for y in range(-3,2):
            for x in range(-3,2):
                if (x,y) in cells:
                    continue
                origin = ((x+0.37)*64,(y+0.61)*64)
                for k in range(16):
                    angle = (k+0.13)*math.tau/16
                    direction = (math.cos(angle),math.sin(angle))
                    left = ray_first(origin,direction,segments(rectangles))
                    right = ray_first(origin,direction,segments(case['polygons']))
                    assert left == right or abs(left-right) < 1e-7, (case['mask'],origin,k,left,right)
                    rays += 1
    result = {'passed':True,'topologies':len(data['cases']),'air_origin_rays':rays,'does_not_establish_rendered_parity':True}
    args.input.with_name('geometry-result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
