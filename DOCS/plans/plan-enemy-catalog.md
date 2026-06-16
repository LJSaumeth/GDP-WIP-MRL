# Implementation Plan: Catálogo de Enemigos y Encuentros

**Date**: 2026-06-16
**Spec**: `DOCS/specs/spec-enemy-catalog.md`

## Summary

Implementar el catálogo de entrenadores enemigos como Resources (`.tres`): datos de entrenadores (nombre, clase, equipo de Pokémon, recompensas), patrones de IA (FIXED/RANDOM/REACTIVE), pools de encuentros por zona y por acto, y escalado de dificultad por acto y Ascensión. Este sistema provee los datos que consumen tanto el combate (`battle_state`, `enemy_ai`) como el overworld (`encounter_system`) y el generador de mapas (`map_generator`).

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `plan-creature-integration.md` (CharacterData, MoveData), `plan-gameplay-deckbuilder.md` (battle_state, enemy_ai, map_generator)
**Storage**: Enemy data in `.tres` Resources; encounter pools in `.tres` Resources
**Testing**: Test scenes in-editor
**Target Platform**: Windows D3D12
**Performance Goals**: Enemy data load <100ms, pool random pick <1ms
**Constraints**: Fallback system prevents crashes on missing data
**Scale/Scope**: ~15 enemy trainers, ~5 encounter pools (zones + acts), 3 AI patterns

## Project Structure

### Source Code (within `wip/`)

```text
src/enemies/
├── resources/
│   ├── enemy_trainer_data.gd      # Resource script: EnemyTrainerData
│   ├── enemy_pokemon_data.gd      # Resource script: EnemyPokemonData (sub-resource)
│   └── encounter_pool.gd          # Resource script: EncounterPool (weighted list)
├── data/
│   ├── trainers/                  # .tres files per enemy trainer (joven_perez.tres, lider_brock.tres, ...)
│   └── pools/                     # .tres files per encounter pool (act1_trainers.tres, ruta1_pool.tres, ...)
├── managers/
│   ├── enemy_database.gd          # Autoload: loads all enemy trainers
│   └── encounter_manager.gd       # Autoload: resolves encounters (random + fixed)
├── ai/
│   ├── enemy_ai_controller.gd     # Runtime: selects intention based on AI pattern
│   └── intention_data.gd          # Resource: Intention (type, value, target, display_text)
└── scaling/
    └── difficulty_scaler.gd       # Scales enemy stats by act + ascension level
```

## Clean Code Guidelines

### Naming & Style
- **Clases**: `PascalCase` — `EnemyTrainerData`, `EnemyPokemonData`, `EncounterPool`, `EnemyAIController`
- **Variables/métodos**: `snake_case` — `trainer_class`, `pick_random()`, `scale_for_act()`
- **Constantes**: `UPPER_SNAKE_CASE` — `ACT_MULTIPLIERS = [1.0, 1.30, 1.60]`
- **Señales**: `snake_case` en pasado — `intention_resolved`, `enemy_defeated`
- **Enums**: `PascalCase` para tipo — `TrainerClass.TRAINER`, `AIPattern.REACTIVE`

### Single Responsibility
- **Resources** (`resources/`, `data/`): Data definition only; no logic
- **Managers** (`managers/`): Loading and querying; no combat logic
- **AI** (`ai/`): Intention selection only; delegates resolution to `move_resolver`
- **Scaling** (`scaling/`): Stat calculations only; pure functions, no side effects

### Métodos
- `pick_random()` debe usar alias method o cumulative weight; no iteración O(n²)
- **Guard clauses**: `if not trainer_data or trainer_data.team.is_empty(): push_error(...); return`
- `enemy_ai_controller.get_intention()` despacha a `_get_fixed_intention()`, `_get_random_intention()`, `_get_reactive_intention()`
- `difficulty_scaler.scale(enemy_data, act, ascension)` — función pura, sin mutar el Resource original

### Godot-Specific
- `enemy_database` as Autoload for global access
- `encounter_manager` as Autoload for resolving encounters
- `EnemyPokemonData` as `Resource` (not Node) — stored inside `EnemyTrainerData.team`
- `@export var ai_pattern: AIPattern` in EnemyPokemonData for editor configuration
- Signals: `SignalBus.encounter_triggered.emit(trainer_data)` for battle scene to consume

### Valores configurables
- ACT_MULTIPLIERS and ASCENSION_MODIFIERS in `@export` or constants, never hardcoded
- AI thresholds (HP < 50% for healing) as `@export var heal_threshold: float = 0.5`
- All encounter pool weights in `.tres` Resources, editable in inspector

## Phases

### Phase 1: Data Resources (Fundacional)

**Purpose**: Define the Resource types for enemy data.

- [ ] T001 Crear `enemy_trainer_data.gd` — Resource con: `id: String`, `display_name: String`, `trainer_class: TrainerClass` (enum TRAINER/ELITE/LEADER), `sprite_path: String`, `team: Array[EnemyPokemonData]`, `reward_pokédollars: int`, `reward_card_pool: Array[String]`
- [ ] T002 Crear `enemy_pokemon_data.gd` — Resource (sub-resource dentro de EnemyTrainerData) con: `character_id: String` (referencia a CharacterData), `level: int`, `move_ids: Array[String]` (2-4 movimientos), `ai_pattern: AIPattern` (FIXED/RANDOM/REACTIVE), `fixed_sequence: Array[String]` (opcional, solo para FIXED)
- [ ] T003 Crear `intention_data.gd` — Resource con: `type: IntentionType` (ATTACK/DEFEND/BUFF/DEBUFF/STATUS/HEAL), `move_id: String`, `value: int` (daño estimado, defensa a ganar, etc.), `display_text: String`, `target: int` (índice del objetivo, 0 = Pokémon activo del jugador)
- [ ] T004 Crear `encounter_pool.gd` — Resource con: `pool_id: String`, `entries: Array[Dictionary]` ({trainer_id: String, weight: float}). Método: `pick_random() → String` (retorna trainer_id según pesos)
- [ ] T005 Crear `.tres` files para al menos 15 entrenadores enemigos con sus equipos (distribuidos entre normales, élites y líderes)
- [ ] T006 Crear `.tres` files para pools de encuentro: 1 por zona overworld inicial + 3 pools por acto roguelike (trainer, elite, leader)

### Phase 2: Database & Encounter Manager

**Purpose**: Autoloads that load and query enemy data.

- [ ] T007 Crear `enemy_database.gd` — Autoload. Carga todos los `.tres` de `data/trainers/` en diccionario `trainer_id → EnemyTrainerData`. Método: `get_trainer(id) → EnemyTrainerData`, `get_all_trainers() → Array`, `get_trainers_by_class(class) → Array`
- [ ] T008 Crear `encounter_manager.gd` — Autoload. Métodos:
  - `get_random_encounter(pool_id) → EnemyTrainerData` — selecciona usando pesos del pool
  - `get_fixed_encounter(trainer_id) → EnemyTrainerData` — para encuentros de historia
  - `get_act_encounter(act_number, node_type) → EnemyTrainerData` — para mapa roguelike
- [ ] T009 Implementar validacion de datos al cargar: si un trainer no tiene moves, asignar ["tackle"] como fallback; si no tiene character_id valido, loguear error y saltar

### Phase 3: AI Controller & Intention System

**Purpose**: Runtime AI that picks enemy intentions each turn.

- [ ] T010 Crear `enemy_ai_controller.gd` — Clase runtime (no Autoload, se instancia por combate). Método `get_intention(pokemon_data: EnemyPokemonData, battle_state: BattleState) → IntentionData`:
  - `_get_fixed_intention()` — avanza `fixed_sequence_position`, wrappea al final
  - `_get_random_intention()` — elige move aleatorio del pool del Pokémon
  - `_get_reactive_intention()` — evalúa condiciones, elige mejor acción
- [ ] T011 Implementar lógica reactiva completa:
  - Si `pokemon.hp_percent < 0.5 AND has_healing_move()` → curarse
  - Si `not has_buff("atk") AND has_buff_move()` → buff de ataque
  - Si `not has_buff("def") AND has_defense_move()` → defensa
  - Else → movimiento de ataque con mayor daño estimado
- [ ] T012 Calcular `display_text` de la intención: "Placaje → 15 daño" (daño = base_dmg × atk_buff del enemigo), "Amnesia → +Defensa", "Tóxico → Envenenar"
- [ ] T013 Actualizar `battle_state.gd` (T010) para usar `enemy_ai_controller.get_intention()` en lugar de lógica inline

### Phase 4: Difficulty Scaling

**Purpose**: Scale enemy stats based on act and ascension level.

- [ ] T014 Crear `difficulty_scaler.gd` — Clase con métodos estáticos:
  - `scale_for_act(base_stats: Dictionary, act: int) → Dictionary` — multiplica HP, ATK, DEF por ACT_MULTIPLIERS[act]
  - `scale_for_ascension(stats: Dictionary, ascension_level: int) → Dictionary` — aplica modificadores de Ascensión
  - `get_leader_level(act: int) → int` — retorna nivel promedio del acto + 2
- [ ] T015 Aplicar escalado al crear `PokemonBattleState` para el enemigo: `difficulty_scaler.scale_for_act()` + `difficulty_scaler.scale_for_ascension()` se aplican en orden
- [ ] T016 No mutar los Resources originales — crear copias de stats al escalar; el `.tres` siempre tiene valores base

### Phase 5: Integration with Existing Systems

**Purpose**: Wire enemy catalog into overworld, map generator, and combat.

- [ ] T017 Integrar con `encounter_system.gd` (overworld): en lugar de `enemy_trainer_ids` hardcodeados, usar `encounter_manager.get_random_encounter(zone_pool_id)`
- [ ] T018 Integrar con `map_generator.gd` (deckbuilder): al generar nodos de combate, usar `encounter_manager.get_act_encounter(act, node_type)` para asignar enemigos
- [ ] T019 Integrar con `battle_state.gd`: al iniciar combate, recibir `EnemyTrainerData`, instanciar `PokemonBattleState` para cada Pokémon enemigo con stats escalados
- [ ] T020 Integrar con `reward_screen.gd`: usar `enemy_trainer_data.reward_card_pool` para la selección de 3 cartas de recompensa post-combate

### Phase 6: Tests

- [ ] T021 Crear escena de test: cargar un entrenador de cada clase, iniciar combate y verificar que los datos se reflejan (nombre, sprite, HP correcto, movimientos)
- [ ] T022 Test de IA: ejecutar 20 turnos con patrón FIXED, verificar secuencia exacta; 20 turnos con RANDOM, verificar que usa movimientos de su pool
- [ ] T023 Test de escalado: verificar que un mismo entrenador en Acto 1 tiene HP base ×1.0 y en Acto 3 tiene HP base ×1.60
- [ ] T024 Test de pool: ejecutar `pick_random()` 1000 veces y verificar distribución (±10% de pesos configurados)

## Dependencies

- **Depende de**: `plan-creature-integration.md` (CharacterData, MoveData usados en enemy definitions)
- **Bloquea**: `plan-gameplay-deckbuilder.md` Phase 4 (enemy_ai necesita este catálogo), `plan-overworld-exploration.md` Phase 5 (encounters necesitan pools)
- **Relacionado con**: `plan-meta-progression.md` (Ascensión modifica enemy stats)
