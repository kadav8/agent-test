# Ashen Crown

A local Godot 4.x combat prototype covering Milestones 1 and 2. The Shrine Yard contains one respawning Hollow Soldier. Win the duel, take the Ember reward, and rest at the shrine to repeat the encounter.

## Run

Import `project.godot` in the Godot Project Manager and press F6 with `world/arena.tscn` open, or press F5 from anywhere. From the command line, run `godot --path .` from this directory. No asset downloads are needed.

| Action | Keyboard / mouse | Controller |
| --- | --- | --- |
| Move | A/D or arrows | Left stick or D-pad |
| Sprint | Hold Ctrl | Hold L3 |
| Jump | Space | South button |
| Roll | Shift | East button |
| Light attack | J or left click | West button |
| Heavy attack | K or right click | Right bumper |
| Guard / parry | Hold / time Q | Left bumper |
| Heal | R | North button |
| Lock on | F | R3 |
| Interact | E | D-pad up |
| Equipment | Tab | Back / Select |
| Pause | Escape | Start |

Tap guard shortly before a frontal attack to parry. A successful parry opens a critical hit. Follow up only when you have enough stamina to attack. Press light attack during a swing to queue the next strike after recovery. Hold off on healing until the soldier is recovering. Controller button mappings are provided, with physical hardware and menu navigation still to verify.

## Milestone 1

- Implemented knight movement, jump, sprint, roll, light attacks, stamina, flasks, and a test arena with one enemy.
- Main files are `world/arena.tscn`, `world/arena.gd`, `actors/player.tscn`, `actors/player.gd`, `actors/enemy.tscn`, `actors/enemy.gd`, and `combat/vitals.gd`.
- Tested keyboard action input, collision with the floor, movement, jumping, roll timing, healing, exhaustion, enemy detection and attacks, death, and respawn.
- Known limits are one arena and one enemy type. Milestone 2 adds the combat mechanics below.

## Milestone 2

- Implemented attack startup, contact and recovery, queued combos, heavy attacks, guard, parry, guard breaks, criticals, reaction and stagger, and an expanded enemy state machine. The three weapons vary in reach, speed, damage, and stamina use.
- Added `combat/strike.gd` and `ui/arena_hud.gd`. Updated the actor and arena scripts. Included `tests/arena_smoke.gd`.
- Added an arena HUD, pause and equipment menus, a rest point, a victory reward, and one recoverable Ember drop. Runtime session progress resets when the game exits.
- Known limits include procedural placeholder art, no audio, and fixed input bindings. Milestone 3 is Forsaken Grave, with hazards, loot, doors, and exploration.

## Verify

Run `godot --headless --path . --script tests/arena_smoke.gd`. The test drives real input actions and physics ticks. It also injects hits in targeted combat-state checks and exits nonzero on failure.
