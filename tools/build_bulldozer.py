"""Build the second game's rounded toy bulldozer in Blender."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import bpy
from toy_parts import ball, box, empty, export, join, material, reset_scene, rod, wheel

reset_scene()
orange = material('Tangerine paint', 'FCA15D')
yellow = material('Sunny roof', 'FFCA52')
blue = material('Blueberry tracks', '344A79')
tread = material('Toy tread', '46618F')
glass = material('Pool blue windows', '56BECF')
white = material('Warm white', 'FFFBEF')
steel = material('Blue hubs', '8ACDE8')
black = material('Friendly pupils', '233A5A')

root = empty('Bulldozer')
body = [box('Chunky orange chassis', (0,.7,0), (2.6,.65,3.0), orange, root, .25)]
for x in (-1.18, 1.18):
    side = 'Left' if x < 0 else 'Right'
    body.append(box(side+' soft track', (x,.53,0), (.78,.96,3.25), blue, root, .36))
    for i, z in enumerate((-1.0, 0, 1.0)):
        wheel(side+' wheel '+str(i), (x,.52,z), .34, .84, steel, white, tread, root)
body += [box('Round rear body', (0,1.12,.92), (2.5,.65,1.0), orange, root, .24),
         box('Cab', (0,1.85,.12), (1.65,1.8,1.65), glass, root, .24),
         box('Sunny roof', (0,2.77,.12), (1.95,.22,1.95), yellow, root, .1),
         box('Engine hood', (0,1.08,-1.05), (1.75,.6,1.05), orange, root, .2)]
# One friendly face on the front window, above the blade.
face_z = -.76
for x in (-.40, .40):
    body.append(ball('Eye', (x,2.05,face_z), (.29,.32,.1), white, root))
    body.append(ball('Pupil', (x+.025,2.05,face_z-.1), (.12,.17,.05), black, root, 10, 8))
for i in range(7):
    x = -.4+i*.133
    body.append(ball('Smile', (x,1.56+.15*(x/.4)**2,face_z-.06), (.075,.045,.035), black, root, 8, 6))
for x in (-1.12, 1.12):
    body.append(box('Blade arm', (x,.51,-1.45), (.2,.24,1.2), blue, root, .08))
# A broad, blunt, slightly curved blade; the three panels form a shallow scoop.
body.append(box('Main pushing blade', (0,.7,-2.04), (3.0,1.28,.32), orange, root, .12))
for x in (-1.63, 1.63):
    wing = box('Blade wing', (x,.7,-2.20), (.65,1.28,.32), orange, root, .1)
    wing.rotation_euler.z = -.4 if x < 0 else .4
    body.append(wing)
body += [box('Blunt cutting edge', (0,.17,-2.23), (3.75,.18,.25), white, root, .07),
         rod('Exhaust', (1.0,1.3,.9), (1.0,1.8,.9), .075, blue, root),
         ball('Beacon', (0,2.95,.5), (.16,.18,.16), orange, root)]
join('Dozer body', body)
export('bulldozer', ROOT)
print('Toy bulldozer exported.')
