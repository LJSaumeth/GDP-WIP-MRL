# AGENTS.md

## Project overview
- Godot 4.6 project, codebase lives in `wip/` — **all file paths are relative to `wip/`**
- Game name: "WIP", a Pokémon fangame (single-player)
- Genre blend: deckbuilder roguelike combat (Slay the Spire-style) + dating sim + 2D-HD exploration
- 3D Forward+ renderer, Jolt Physics engine, D3D12 on Windows
- Language: GDScript (`.gd` files) + Godot scenes (`.tscn`)

## Commands
- No formal build/test/lint commands. Open the project in Godot editor: `godot --editor wip/project.godot`
- No CI, no test suite
- Test scenes are built manually in Godot editor as `.tscn` files

## Architecture
- **`wip/`** — the Godot project root
- **`wip/addons/`** — third-party plugins (do not modify without intent):
  - `sprouty_dialogs` — graph-based dialog system with translation support (used for all game dialogue)
  - `sound_manager` — audio: sound effects, music, ambient
  - `input_helper` — input handling utilities
- **`DOCS/`** — design documents (gitignored). Contains 5 specs + 5 implementation plans:
  - `spec-gameplay-deckbuilder.md` — combat system (moves, decks, Furor bar, map)
  - `spec-creature-integration.md` — creatures, evolutions, card pools, teams of 3
  - `spec-overworld-exploration.md` — 2D-HD movement, zones, NPCs, day/night cycle
  - `spec-dating-sim.md` — affinity, relationships, Harem/Netori, dates
  - `spec-meta-progression.md` — story mode, Roguelike access, NG+, Ascension, save system
  - Matching `plan-*.md` files with phased implementation tasks
- **`src/`** (planned, not yet created) — will contain gameplay scripts under `wip/src/`:
  - `creatures/`, `combat/`, `overworld/`, `dating/`, `progression/`

## Key architectural decisions (non-obvious)

### Roguelike is NOT a separate mode
- The Roguelike (deckbuilder runs) is accessed FROM within the story mode, NOT from the main menu
- Access points exist as interactable locations in the overworld (e.g., "Battle Arena")
- Story state is preserved when entering/exiting Roguelike

### Furor system (not one-use-per-combat)
- Special mechanics (Mega Evolution, Z-Moves, Gigantamax, Terastalization) use a **Furor bar** (max 10)
- Furor accumulates during combat (playing moves, taking damage, healing)
- Each mechanic costs X furor; can be used multiple times and combined on the same Pokémon

### One creature per character
- Each character has exactly ONE creature assigned; the pair is a `CharacterVersion` entity
- The creature defines the character's card pool (moves)
- Only the protagonist can rotate between creatures; all others are fixed
- Card commons persist after evolution; exclusives are replaced

### Dating sim constraints
- Harem (default false): limits to 1 partner; true = unlimited
- Netori (default false): married characters not romanceable; true = they are
- Both flags set at new game start, immutable per save
- Affinity can't drop once "In Love" state is reached

## Conventions
- `.godot/` is gitignored (editor cache); never commit it
- Root `.gitignore` ignores `DOCS/`, agent files, and OpenCode artifacts
- `DOCS/plan-template.md` and `DOCS/spec-template.md` are planning scaffolds
- Line endings: LF (set in `.gitattributes`)
- GDScript uses tabs for indentation (Godot default)
- Feature workflow: spec → plan → implement (consult corresponding `plan-*.md` before writing code)
