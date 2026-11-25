# Ashen Oath · Grave of Kings

Milestone 3 expands the Ashen Crown combat prototype into an eleven-room expedition. Start at Ashen Shrine, descend through a royal burial ground, and release the Bell Tower lift to open a direct route back to the sanctuary. The expedition ends at the Bell Warden's fog gate.

## Run

Import `project.godot` in Godot 4 and press **F5**, or run `godot --path .` from this directory. Godot 4.7.2 was used for verification. Art and sound are generated in the project. A copy of the original practice arena remains available as `world/arena.tscn`.

| Action | Keyboard / mouse | Controller |
| --- | --- | --- |
| Move | A/D or arrows | Left stick or D-pad |
| Sprint | Hold Ctrl | Hold L3 |
| Jump | Space | South button |
| Roll | Shift | East button |
| Light / heavy strike | J / K or left / right click | West button / right bumper |
| Guard / parry | Hold / time Q | Left bumper |
| Heal | R | North button |
| Lock on | F | R3 |
| Interact / advance dialogue | E | D-pad up |
| Equipment and items | Tab | Back / Select |
| Pause / leave dialogue | Esc | Start |

Interact with doors to change rooms. Locked passages and the lift take a second interaction to enter after you open them. Bonfires restore resources and reset normal encounters throughout the region. The Vigil Sword starts equipped. Exploration unlocks the existing Ash Daggers and Grave Cleaver.

## Saves

The new JSON save at `user://grave_of_kings.save` records souls, inventory, equipment, bonfires, doors, shortcuts, secrets, dialogue completion, and the active recovery marker. It also records the current room and the safe entry used to reach it. Progress saves on room travel, permanent interactions, equipment changes, death, and window close. It keeps one previous snapshot for recovery if the primary save becomes unreadable. Reloads start at the saved room entry with saved resources and fresh normal enemies. The prototype arena had no persistent saves.

## Project files

| Path | Purpose |
| --- | --- |
| `world/region/expedition.tscn`, `expedition.gd` | One player, camera, and HUD across all room transitions; interaction, checkpoint, and soul recovery integration |
| `world/region/layout.gd`, `room.gd` | Handcrafted room layout, stable identifiers, encounter placement, reusable terrain and room construction |
| `world/region/landmark.gd`, `world_state.gd` | Doors, keys, lift, bonfires, loot, secret, NPC and fog gate interaction data; save and backup |
| `world/region/scenery.gd`, `atmosphere_audio.gd` | Original procedural gothic scenery, lighting, ash, fog, and synthesized room audio |
| `ui/expedition_hud.gd`, `ui/arena_hud.gd` | Expedition HUD, dialogue, equipment and item descriptions; shared menu and drawing helpers |
| `world/controls.gd`, `world/arena.gd` | Shared prototype input bindings and retained practice arena |
| `actors/player.gd`, `actors/enemy.gd` | Multiple combat targets, room relocation, enemy territories, and coordinated attack starts |
| `project.godot`, `tests/expedition_smoke.gd` | Expedition entry point and integration coverage |

## Testing

Run from the project directory.

```sh
godot --headless --fixed-fps 60 --path . --script tests/arena_smoke.gd
godot --headless --fixed-fps 60 --path . --script tests/expedition_smoke.gd
```

The expedition test uses movement, jump and interaction input to reach each area, visit optional routes, collect every pickup, and check lock ordering and both sides of the lift. It fights the Cemetery Gates soldier with a live AI and suspends other enemies for the route and geometry checks. Separate tests inject deaths in eight regional rooms and trigger a real pit fall to verify checkpoint and soul recovery behavior. Reload tests cover doors, keys, loot, inventory, markers, and recovery from a truncated save.

A rendered keyboard smoke check covered the opening sanctuary, Ashkeeper dialogue and the transition into Cemetery Gates. Full human playtesting, first-play duration, controller hardware, audio listening, and a sustained 60 FPS target remain unverified. The Bell Warden entrance stays closed and reports that the encounter is unavailable. The expedition includes the transition signal for a future boss implementation.
