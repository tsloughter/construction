# EARTHWORK

A playable construction-game starter made with **Godot 4** and **Blender**. Take the EW–240 excavator into a small quarry yard, scoop a boulder, move it, and tip it into the material bay.

## Play

Open `project.godot` in Godot 4.4 or newer and press **F6** from the main scene or **F5** to run the project. No plugins or asset downloads are required. The project was built and tested with the installed Godot 4.7.2 and Blender 5.2.0.

On Linux, the launcher detects native Godot or the installed Flatpak:

```sh
./run.sh         # play
./run.sh edit    # open the Godot editor
./run.sh test    # import assets and run physics/input integration checks
./run.sh capture # save a screenshot to screenshots/yard.png
```

The first boulder starts inside the open bucket's working area. Press **Space**, then **B** to lift it to travel height. Drive toward the mint-colored delivery bay, position the **bucket** above it, and press **Space** again. A boulder counts after it settles inside the bay. Deliver all three to complete the shift; you can keep playing afterward.

You can also drop and scoop rocks anywhere in the yard. The marked bay is a small optional objective for practicing the construction loop.

## Controls

| Input | Action |
|---|---|
| W / S | Drive forward / reverse |
| A / D | Steer the tracks, including turning in place |
| Q / E | Swing the upper body independently |
| Up / Down | Raise / lower the bucket |
| Left / Right | Retract / extend the arm |
| Space | Curl and scoop a nearby rock; tip if carrying |
| B | Raise and retract to a safe travel pose |
| Hold right mouse | Orbit the camera |
| Mouse wheel | Zoom |
| C | Toggle yard overview |
| F | Refocus the camera behind the machine |
| Tab | Operator guide |
| Escape | Pause / resume (also available as a mouse button) |
| R | Reset the yard, including the machine and every boulder |
| M | Mute / unmute machine audio |

## What is implemented

- Custom Blender excavator with tread shoes, cab, engine housing, bucket teeth, hydraulic details, and separate upper-body, boom, stick, bucket, and carry-socket pivots.
- Character-body driving and steering, independent cab swing, and a two-link inverse-kinematics arm with bounded reach.
- A hollow bucket collision shape and proximity-gated scoop interaction. The pickup indicator appears only when a rock is inside the open mouth.
- Assisted bucket retention: curling secures one rock to a carry socket. Tipping releases it as a Godot rigid body with gravity, collision, friction, and a small outward velocity.
- Three movable boulders, a delivery area, settling-based progress, completion feedback, reset, and pause.
- Orbit/overview camera, contextual controls, a yard map, machine telemetry, and original synthesized engine/hydraulic sounds.
- A quarry environment with containers, an office, fencing, cones, gravel, pipes, timber, and distant hills.

This is a first playable prototype. It uses assisted retention for reliable loading; it does not yet simulate loose soil, digging terrain, hydraulic forces, or a fully physical tracked drivetrain. Bucket metal can contact loose rocks, while a secured load follows the bucket until released. The visual hydraulic cylinders are stylized details rather than a full linkage simulation.

## Project layout

| Path | Purpose |
|---|---|
| `scenes/main.tscn` | Main game scene |
| `scripts/main.gd` | Scene assembly, input bindings, reset, audio, objective |
| `scripts/excavator.gd` | Driving, arm IK, scoop/carry/drop state |
| `scripts/boulder.gd` | Rigid-body rocks and settled delivery detection |
| `scripts/yard.gd` | Procedural yard construction and lighting |
| `scripts/orbit_camera.gd` | Camera controls |
| `scripts/hud.gd` | Interface, guide, map, pause controls |
| `art/excavator.blend` | Editable excavator source |
| `art/boulder.blend` | Editable boulder source |
| `assets/models/*.glb` | Blender exports used by Godot |
| `tools/build_assets.py` | Reproducible Blender modeling/export script |
| `tools/build_audio.py` | Original audio generation script |
| `tests/gameplay_test.gd` | Physics/input integration test |

The yard is assembled at runtime, so press Play to see it in Godot. The exported models can be opened independently in the editor. `art/.gdignore` keeps Blender source files out of Godot's import pipeline; Blender is required only when editing or rebuilding the models.

## Rebuild assets

```sh
blender --background --factory-startup --python tools/build_assets.py
# Or, with Blender installed from Flathub:
flatpak run org.blender.Blender --background --factory-startup --python "$PWD/tools/build_assets.py"
python3 tools/build_audio.py
```

Blender helpers use Godot coordinates and convert to Blender's Z-up system. Keep the node names `Upper`, `Boom`, `Stick`, `Bucket`, and `CarrySocket` when changing the model. Regenerating overwrites the two `.blend` files and both GLBs, so preserve manual modeling edits before rerunning the generator.

Models, yard geometry, UI, and audio were created for this project. Roboto and Source Code Pro font licenses are included in `assets/fonts/`.

## Validation

The integration run passes **28 checks**, including the entire three-boulder mission using simulated player inputs, independent cab rotation, loaded transport, dynamic release and settling, pause, reset during an active scoop, out-of-range pickup rejection, and arm reach limits. The rendered game was also checked on the installed Intel Iris Xe graphics. See `screenshots/yard.png` for an actual gameplay capture.
