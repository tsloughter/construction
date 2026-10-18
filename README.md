# Little Builders

Two cheerful, toy-like **construction games** for children around **3–5 years old**. Choose the excavator or bulldozer from the opening picture screen. Both games have a fixed camera, simple directional controls, and three optional keepsake stars.

The detailed construction prototype is on **`expert`**, and the earlier sandbox version is on **`preschool`**. The toy construction-site version is being developed on **`main`**.

A complete local backup of the preschool version, including the supporting files that were still untracked, is saved at `.local_backups/preschool-complete.zip`. Neither saved branch was changed.

After switching branches, open the project in the Godot editor to refresh the imported models. The launcher on `main` also refreshes them automatically.

## Play together

Run `./run.sh`, or open `project.godot` in Godot and press **F5**.

The opening screen has two large vehicle pictures. Click or tap either picture to start. Keyboard selection also works: Left/Right then Enter, or 1 for excavator and 2 for bulldozer. The **house button** in either game returns to the chooser; choosing a game starts a fresh round. Sound preferences carry across games.

### Excavator: scoop & carry

**The easiest way — just click:**

1. Click a colorful rock. The digger drives over, turns, scoops it, and lifts it automatically.
2. Click the big star or green circle. The digger carries the rock over and puts it down.
3. Click another rock and keep playing!

**For a child who wants to drive:**

- **Arrow keys** move in the direction of the arrow on the screen. The digger turns itself. WASD also works.
- **Space** collects the nearest available rock, or puts down the rock being carried.
- The large **picture buttons** do the same things with a mouse or touch input.
- Clicking an empty patch of sand sends the digger there. An arrow press takes over from automatic driving.

No reading, camera controls, separate steering, or arm controls are required. The arm lowers and raises itself. A keyboard or picture-button drop can happen anywhere; the star-marked material bay is an optional activity.

### Bulldozer: push & fill

- Drive the orange bulldozer into a boulder with the **arrow keys**, **WASD**, or the large direction buttons. The broad blade pushes it along the ground.
- Push the boulder into any of the **three wide, yellow-rimmed holes**. It falls in, the hole fills, and a star appears. There is no color-matching requirement.
- For help, **tap a boulder**, press **Space**, or tap the big **PUSH** picture. The bulldozer lines up behind a rock and pushes it toward an open hole automatically. An arrow press takes over immediately.
- Click an empty spot to drive there. Keep driving after all three holes are filled, or use **Start again** in the pause menu for another round.

The rocks are free physics bodies while being pushed. The vehicle is supported over the holes so children cannot get it stuck in one. Lost boulders return quietly.

## A relaxed place to play

- No timer, failure state, lives, or penalties.
- One little star for each different pebble delivered in the excavator game, or each hole filled in the bulldozer game.
- Stars stay earned even if a pebble is picked up again.
- Finishing all three gives a little celebration and lets play continue.
- The site keeps the vehicle in view; a lost pebble quietly returns.
- A fixed camera makes the movement directions consistent.
- Soft toy sounds and short chimes, with a sound toggle in the pause menu.

The controls support mouse and Godot touchscreen input. Mouse and touch dispatch were tested in the engine; this project has not been exported or tested on a physical tablet.

## A real job site, drawn like toys

The wooden sandbox rim has been replaced with a level dirt work yard, an entrance road, painted lanes, striped barriers, cones, a storage container, an office, stacked pipes, lumber, bricks, floodlights, a building frame, and a small tower crane. The materials use the same soft edges and cheerful colors as the digger.

The playable center stays clear. The camera stays fixed, and the same three-rock goal, picture buttons, automatic arm, gentle sounds, and no-pressure rewards remain. The floating star now marks the material-delivery bay.

## For parents

The **pause picture in the upper-right corner** opens a small menu with resume, start-again, choose-game, and sound buttons.

Keyboard shortcuts for grown-ups: **Escape** pauses, **R** starts again, and **M** toggles sound. Movement buttons release when the pointer leaves and is released, or when the window loses focus.

```sh
./run.sh         # play
./run.sh edit    # Godot editor
./run.sh test    # import and run gameplay/input tests
./run.sh capture # opening.png, yard.png, bulldozer.png in screenshots/
```

The launcher detects native Godot or the installed Godot Flatpak. Built and tested with Godot 4.7.2 and Blender 5.2.0. Imported GLBs are included, so Blender is not needed to play.

## Editable project

| File | What it controls |
|---|---|
| `project.godot` | Open this in Godot |
| `scenes/opening.tscn` / `scripts/app.gd` | Opening screen and switching between independent game worlds |
| `scripts/opening_menu.gd` / `scripts/game_card.gd` | Picture chooser with real Blender model previews |
| `scenes/main.tscn` | Original excavator scene, also playable directly |
| `scripts/main.gd` | Click/tap interaction, rewards, pause, reset, sounds |
| `scripts/bulldozer_game.gd` | Second game: rock selection, filled-hole rewards, and restart |
| `scripts/bulldozer.gd` | Direct driving, physical pushing, and optional approach/push assist |
| `scripts/dozer_yard.gd` / `scripts/fill_hole.gd` | Perforated terrain, holes, and completed-hole plugs |
| `scripts/dozer_layout.gd` / `scripts/push_boulder.gd` | Starting positions and rolling boulder physics |
| `scripts/excavator.gd` | Directional driving and automatic scoop/carry/drop sequence |
| `scripts/playground.gd` | Driving limits, rock positions, colors, and delivery-bay location |
| `scripts/yard.gd` | Rounded construction-site scenery |
| `scripts/hud.gd` | Picture controls, stars, and parent menu |
| `scripts/toy_button.gd` | Mouse/touch buttons with release handling |
| `scripts/boulder.gd` | Pebble physics and automatic recovery |
| `scripts/orbit_camera.gd` | Fixed camera (filename retained from the earlier project) |
| `art/bulldozer.blend` / `tools/build_bulldozer.py` | Editable rounded bulldozer and its Blender generator |
| `art/excavator.blend` | Editable rounded toy excavator |
| `art/boulder.blend` | Editable soft pebble |
| `art/site_props.blend` | Shared Blender block with rounded edges for site props |
| `tools/build_site_props.py` | Regenerates the rounded site block |
| `tools/build_assets.py` | Blender asset generator |
| `tools/build_audio.py` | Original sound generator |
| `tests/gameplay_test.gd`, `tests/bulldozer_test.gd`, `tests/menu_test.gd` | Excavator, pushing physics, and game-switching integration checks |

The excavator keeps the original project's arm pivots and two-link arm math, with a simpler toy model and automatic controls. Rocks are secured to the bucket for reliable carrying and return to gravity/collisions when dropped. The bulldozer uses a separate rolling-rock physics setup and prebuilt holes; there is no arbitrary terrain deformation.

To regenerate assets:

```sh
flatpak run org.blender.Blender --background --factory-startup --python "$PWD/tools/build_assets.py"
flatpak run org.blender.Blender --background --factory-startup --python "$PWD/tools/build_site_props.py"
flatpak run org.blender.Blender --background --factory-startup --python "$PWD/tools/build_bulldozer.py"
python3 tools/build_audio.py
```

A native Blender installation can run the same script with `blender --background --factory-startup --python tools/build_assets.py`. The generator overwrites the `.blend` files and GLBs; save manual modeling changes elsewhere before regenerating.

## Checks

The automated suite exercises direct directional movement, stopping, a fixed camera, actual viewport dispatch for mouse and touch buttons, release outside buttons, one-button collection and free dropping, collecting all three rocks through generous click targets, automatic material-bay delivery, persistent/non-duplicated rewards, interruption of automatic driving, pause and restart during a scoop, lost-rock recovery, site boundaries, and mute.

The bulldozer suite also checks direct physical pushing, actual falling into holes, assisted delivery, displaced boulders, duplicate rewards, restarting and refilling, touch release, and recovery. The opening-screen suite dispatches mouse, touch, and keyboard input and checks world cleanup, paused navigation, and sound preferences.

The games and opening screen are visually checked through native Godot renders. Font licenses are included in `assets/fonts/`; models, scenery, UI, and sounds were created for this project.

## License

Copyright (C) 2026 Tristan Sloughter.

Little Builders, including its source code and original models, scenery, UI, and sounds, is free software: you can redistribute it and/or modify it under the terms of the **GNU Affero General Public License**, either version 3 of the License, or (at your option) any later version (**SPDX: AGPL-3.0-or-later**). The full license is in [LICENSE](LICENSE).

This project is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of **MERCHANTABILITY** or **FITNESS FOR A PARTICULAR PURPOSE**. See the GNU Affero General Public License for more details.

Source code is available at [tsloughter/construction](https://github.com/tsloughter/construction).

### Third-party notices

- **Godot Engine** is distributed under the [MIT license](https://godotengine.org/license/), with copyright held by the Godot Engine contributors and Juan Linietsky and Ariel Manzur. Godot's bundled libraries have their own notices in its [COPYRIGHT.txt](https://github.com/godotengine/godot/blob/master/COPYRIGHT.txt).
- **Roboto** is distributed under the [Apache License 2.0](assets/fonts/Roboto-LICENSE.txt).
- **Source Code Pro** is copyright 2023 Adobe and distributed under the [SIL Open Font License 1.1](assets/fonts/SourceCodePro-LICENSE.md).

The engine and fonts retain their respective licenses.

When distributing a Godot export, ship `LICENSE`, this `README.md`, and both font license files as accompanying documentation. Also include the Godot `COPYRIGHT.txt` matching the engine/export-template version, renamed to `GODOT_COPYRIGHT.txt`, for its bundled third-party libraries, as described in [Godot's license guidance](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html). Godot does not automatically export non-resource documentation, so copy these files alongside the executable or explicitly include them in the export's non-resource file filters. Provide the corresponding source for the distributed version under the AGPL's terms; if a modified version supports remote network interaction, offer those users access to its corresponding source as required by section 13.
