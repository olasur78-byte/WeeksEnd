# Weeks End

The game's code was extracted from `Weeks End.rbxl` into Luau source files and
connected through [Rojo](https://rojo.space/). The original place file remains
the source of the map, user interfaces, models, and other instances that this
project does not overwrite.

## Project structure

- `src/Server` — scripts and modules from `ServerScriptService`
- `src/Client` — scripts from `StarterPlayerScripts`
- `src/Shared` — modules from `ReplicatedStorage`
- `src/ReplicatedStorage` — scripts stored directly in `ReplicatedStorage`
- `src/ServerStorage` — server-side modules for monster models
- `raw-scripts` — an unchanged reference export with its manifest

## Working with Roblox Studio

1. Open `Weeks End.rbxl` in Roblox Studio.
2. Run `rojo serve default.project.json` from the project directory.
3. Connect the Rojo plugin in Studio to the running server.

The project configuration preserves unknown instances. Synchronizing the code
should not remove the map, models, RemoteEvents, or UI elements stored in the
original place file.

## Export verification

`raw-scripts/manifest.json` records the original path and class of each of the
31 recovered scripts. The files in `src` initially mirror the source code;
future refactoring should happen in `src`, while `raw-scripts` remains an
unchanged reference copy.

## Gameplay systems

The game currently includes a server-side round loop, shared-home selection for
the kidnapper and victim, a day-and-night cycle, victim needs and escape tasks,
monster cover tasks, interactive interrogation responses, NPCs with randomized
appearances and walking animations, evidence that narrows down six monster
types, daily CCTV monitoring, and a victory condition that requires rescuing the
victim and identifying the monster.

The tags used to connect these systems to map geometry are documented in
`docs/GameplayTags.md`.
