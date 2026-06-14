# Implementation Plan: Integración de Criaturas

**Date**: 2026-06-12
**Spec**: `DOCS/spec-creature-integration.md`

## Summary

Implementar el sistema de criaturas como capa fundacional: cada personaje tiene 1 criatura fija, la criatura define el pool de movimientos (cartas), soporte de evolución por nivel + materiales, y composición de equipo de 3 personajes. Solo el protagonista puede rotar entre criaturas. Base de datos de criaturas con stats, evoluciones y pools de cartas.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot Resource system (`.tres`), JSON/CSV data
**Storage**: Godot Resources + JSON para datos de criaturas/movimientos/evoluciones
**Testing**: Test scenes in-editor (Godot no tiene test runner nativo)
**Target Platform**: Windows D3D12
**Project Type**: Single-player Godot project
**Performance Goals**: <16ms por frame (60fps), carga de datos de criaturas <200ms
**Constraints**: Datos cargados en memoria al inicio, no consultas runtime pesadas
**Scale/Scope**: ~50 criaturas, ~10 lineas evolutivas, ~200 movimientos (cartas)

## Project Structure

### Source Code (within `wip/`)

```text
src/creatures/
├── data/                       # Datos crudos de criaturas y movimientos
│   ├── creatures.json           # Todas las criaturas base (stats, evoluciones, pool IDs)
│   ├── evolutions.json          # Reglas de evolución (nivel, material, destino)
│   ├── moves.json               # Pool de movimientos (nombre, daño, coste, efectos)
│   └── materials.json           # Materiales de evolución
├── resources/                   # Godot Resources (.tres) generados desde JSON
│   ├── creature_data.gd         # Resource: CreatureData
│   ├── move_data.gd             # Resource: MoveData
│   ├── evolution_data.gd        # Resource: EvolutionData
│   └── character_version.gd     # Resource: CharacterVersion (personaje + criatura)
├── managers/
│   ├── creature_database.gd     # Singleton: carga y provee datos de criaturas
│   ├── move_database.gd         # Singleton: carga y provee datos de movimientos
│   └── evolution_manager.gd     # Lógica de evolución (checks, trigger, animación)
├── state/
│   ├── team_state.gd            # Estado runtime del equipo (3 CharacterVersion)
│   ├── creature_instance.gd     # Estado runtime de una criatura (nivel, XP, evoluciones pendientes)
│   └── character_roster.gd      # Todas las versiones de personaje desbloqueadas
└── ui/
    ├── creature_viewer.gd       # Pantalla de visualización de criatura
    ├── evolution_screen.gd      # UI de evolución (opciones ramificadas)
    └── team_selector.gd         # UI de selección de equipo
```

## Phases

### Phase 1: Datos y Resources (Fundacional)

**Purpose**: Definir la estructura de datos y crear los Resources de Godot que todo el sistema usará.

- [ ] T001 Crear `creature_data.gd` — Resource con: id, nombre, tipos elementales, sprite_path, stats_base (HP, ATK, DEF, SPD), pool_move_ids, evolution_ids
- [ ] T002 Crear `move_data.gd` — Resource con: id, nombre, descripción, coste_energía, tipo_elemental, categoría (Físico/Especial/Estado), rareza, efectos (diccionario de efectos aplicables)
- [ ] T003 Crear `evolution_data.gd` — Resource con: creature_origen_id, creature_destino_id, nivel_requerido, material_requerido_id, tipo (nivel/historia/ramificada)
- [ ] T004 Crear `character_version.gd` — Resource con: character_id, creature_id, sprite_personaje, sprite_criatura, move_pool_override (opcional)
- [ ] T005 Crear `creatures.json` con datos de al menos 5 criaturas (3-stage evolutions: ej. Pikachu→Raichu, Charmander→Charmeleon→Charizard)
- [ ] T006 Crear `moves.json` con al menos 20 movimientos (5 por criatura)
- [ ] T007 Crear `evolutions.json` con reglas de evolución para las 5 criaturas
- [ ] T008 Crear `materials.json` con materiales de evolución (Piedra Trueno, Piedra Fuego, etc.)

### Phase 2: Database Managers (Singletons)

**Purpose**: Autoloads que cargan los JSON y proveen acceso rápido a los datos. Todas las queries son O(1) vía diccionarios.

- [ ] T009 Crear `creature_database.gd` — Autoload, carga `creatures.json` en diccionario `creature_id → CreatureData`, método `get_creature(id)` y `get_move_pool(creature_id)`
- [ ] T010 Crear `move_database.gd` — Autoload, carga `moves.json` en diccionario `move_id → MoveData`, método `get_move(id)`, `get_moves_for_creature(creature_id)`
- [ ] T011 Crear `evolution_manager.gd` — Autoload, carga `evolutions.json`, método `check_evolution(creature_instance) → EvolutionData|null`, método `get_available_evolutions(creature_id, nivel, inventario_materiales)`

### Phase 3: Estado Runtime de Criaturas

**Purpose**: Manejar el estado vivo de las criaturas durante el juego: niveles, XP, evolución pendiente, instancia activa.

- [ ] T012 Crear `creature_instance.gd` — Clase que envuelve CreatureData con estado runtime: nivel_actual, xp_actual, esta_evolucionada (bool), evolution_history (lista de evoluciones realizadas)
- [ ] T013 Implementar `creature_instance.gain_xp(amount)` — Suma XP, verifica si alcanza nivel para evolución, retorna `EvolutionData` si aplica
- [ ] T014 Implementar `creature_instance.evolve(evolution_data)` — Cambia creature_id interno, actualiza stats base, retorna nuevo CreatureData

### Phase 4: Composición y Gestión de Equipo

**Purpose**: Sistema de equipo de 3 personajes, selección y validación. Solo el protagonista rota criaturas.

- [ ] T015 Crear `team_state.gd` — Mantiene array[3] de CharacterVersion, índice de activo, métodos `add_member(version)`, `remove_member(index)`, `swap_creature(index, new_creature_id)` (solo para protagonista)
- [ ] T016 Crear `character_roster.gd` — Registro de todas las CharacterVersion desbloqueadas por el jugador, métodos `unlock(version)`, `get_unlocked()`, `is_unlocked(version_id)`
- [ ] T017 Implementar validación: no permitir equipo sin criatura asignada, no permitir rotación en no-protagonistas

### Phase 5: UI de Criaturas

**Purpose**: Pantallas de visualización y selección.

- [ ] T018 Crear `creature_viewer.gd` + `.tscn` — Muestra sprite, stats, nivel, evoluciones disponibles, pool de movimientos de una criatura
- [ ] T019 Crear `evolution_screen.gd` + `.tscn` — Muestra opciones de evolución ramificada con previsualización de stats, confirma selección
- [ ] T020 Crear `team_selector.gd` + `.tscn` — Grid de 3 slots, arrastrar personajes del roster al equipo

### Phase 6: Integración y Tests

- [ ] T021 Crear `test_creature_scene.tscn` — Escena de prueba con criatura viewer, botones para subir nivel, trigger evolución, seleccionar equipo
- [ ] T022 Validar que al evolucionar una criatura: (a) sprite cambia, (b) stats se actualizan, (c) pool de movimientos se expande con nuevos movimientos exclusivos
- [ ] T023 Validar que solo el protagonista puede rotar criatura y los demás personajes tienen criatura fija

## Dependencies

- **Bloquea**: `plan-gameplay-deckbuilder.md` (los mazos dependen del pool de movimientos de cada criatura)
- **Depende de**: Nada (es fundacional)
