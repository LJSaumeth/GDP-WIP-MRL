# Implementation Plan: Integración de Criaturas

**Date**: 2026-06-12
**Spec**: `DOCS/spec-creature-integration.md`

## Summary

Implementar el sistema de criaturas como capa fundacional: cada personaje tiene 1 criatura fija, la criatura define el pool de movimientos (cartas), soporte de evolución por nivel + materiales, y composición de equipo de 3 personajes. Solo el protagonista puede rotar entre criaturas. Base de datos de criaturas con stats, evoluciones y pools de cartas.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot Resource system (`.tres`)
**Storage**: Godot Resources (`.tres`) para todos los datos de criaturas/movimientos/evoluciones
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
├── resources/                     # Godot Resources (.tres) — definiciones de datos
│   ├── type_enum.gd                # Enum: Type (18 tipos) + to_string/from_string helpers
│   ├── character_data.gd           # Resource script: CharacterData
│   ├── move_data.gd                # Resource script: MoveData
│   ├── material_data.gd            # Resource script: MaterialData
│   ├── type_chart_data.gd          # Resource script: TypeChartData
│   ├── characters/                 # .tres files (prota_pikachu.tres, misty_starmie.tres, ...)
│   ├── moves/                      # .tres files por movimiento (placaje.tres, lanzallamas.tres, ...)
│   └── materials/                  # .tres files por material (piedra_trueno.tres, ...)
├── managers/
│   ├── character_database.gd       # Autoload: carga y provee datos de personajes
│   ├── move_database.gd            # Autoload: carga y provee datos de movimientos
│   └── evolution_manager.gd        # Logica de evolucion (consulta evolution_options del CharacterData)
├── state/
│   ├── team_state.gd               # Estado runtime del equipo (3 CharacterData)
│   ├── character_instance.gd       # Estado runtime: nivel, XP, evoluciones pendientes
│   └── character_roster.gd         # Todos los CharacterData desbloqueados
└── ui/
    ├── character_viewer.gd         # Pantalla de visualizacion
    ├── evolution_screen.gd         # UI de evolucion (opciones ramificadas)
    └── team_selector.gd            # UI de seleccion de equipo
```

## Clean Code Guidelines

### Naming & Style
- **Clases**: `PascalCase` — `character_data.gd` define `class_name CharacterData`
- **Variables/métodos**: `snake_case` — `current_hp`, `take_damage()`, `get_move_pool()`
- **Constantes**: `UPPER_SNAKE_CASE` — `MAX_TEAM_SIZE = 3`
- **Señales**: `snake_case` en pasado — `evolution_completed`, `character_swapped`
- **Nodos hijos**: `PascalCase`, igual que la clase que contienen

### Single Responsibility
- **Resources** (`resources/`): `.tres`/`.gd` con datos puros, sin logica de runtime
- **Managers** (`managers/`): Autoloads con logica de acceso y consulta (O(1) via diccionarios)
- **State** (`state/`): Estado runtime mutable, solo getters/setters y validacion
- **UI** (`ui/`): Solo presentacion; delega toda logica a managers/state
- Si un manager supera ~200 lineas, extraer queries complejas a un helper dedicado

### Métodos
- Máximo ~30 líneas por método; extraer bloques a métodos privados con nombre descriptivo
- **Guard clauses**: retornar temprano si condiciones no se cumplen (`if not creature: return`)
- Un solo nivel de abstraccion por metodo — no mezclar lectura de Resources con logica de negocio
- Evitar más de 3 niveles de indentación

### Godot-Specific
- `@onready var node := $Path/To/Child` para referencias — nunca `get_node()` en runtime
- `@export var data: CharacterData` para asignar Resources desde el editor
- **Señales sobre llamadas directas**: `SignalBus.character_evolved.emit(character)` en vez de `parent.on_evolution()`
- Tipado explícito en todas las declaraciones: `func get_character(id: String) -> CharacterData`

### Valores configurables
- Stats base, umbrales de evolución y costes en Resources (`.tres`), nunca hardcodeados
- `.tres` Resources como fuente de verdad; los `.gd` scripts solo definen la estructura, no los datos
- Usar `@export var max_team_size: int = 3` para límites que puedan cambiar

## Phases

### Phase 1: Datos y Resources (Fundacional)

**Purpose**: Definir la estructura de datos y crear los Resources de Godot que todo el sistema usará.

- [ ] T000 Crear `type_enum.gd` — `enum Type` con los 18 tipos Pokemon. `static func to_string(t: Type) → String`, `static func from_string(s: String) → Type`. Usado por CharacterData, MoveData y TypeChartData
- [ ] T001 Crear `character_data.gd` — Resource unico que fusiona personaje + criatura + evoluciones:
  - Identidad: `id`, `display_name`, `character_id`, `is_protagonist`, `character_sprite`, `creature_sprite`
  - Stats base: `types: Array[TypeEnum.Type]`, `base_hp`, `base_atk`, `base_def`, `base_spd`
  - Pool de movimientos: `move_pool_ids[]` (cartas disponibles para esta version)
  - Evoluciones: `evolution_options[]` (Array[Dictionary] con `{dest_id, required_level, required_material_id, evo_type}`)
- [ ] T002 Crear `move_data.gd` — Resource con: id, nombre, descripcion, energy_cost, elemental_type: TypeEnum.Type (editor dropdown), category (PHYSICAL/SPECIAL/STATUS), rarity (BASIC/COMMON/UNCOMMON/RARE), base_damage, self_defense_gain, status_effect, status_chance, buff_target, buff_stat, buff_amount, is_exclusive
- [ ] T003 Crear `material_data.gd` — Resource con: id, display_name, description, sprite_path
- [ ] T004 Crear `type_chart_data.gd` — Resource con tabla de tipos elemental como diccionario `Dictionary[String, Dictionary[String, float]]` (keys en string para legibilidad del .tres). Crear `type_chart.tres` con multiplicadores (×2, ×1, ×0.5, ×0). El move_resolver convierte TypeEnum.Type → String via `TypeEnum.to_string()` antes de hacer lookup
- [ ] T005 Crear archivos `.tres` para al menos 5 personajes usando `character_data.gd` (ej: prota_pikachu, prota_charmander, prota_bulbasaur, misty_starmie, brock_onix)
- [ ] T006 Crear archivos `.tres` para al menos 20 movimientos usando `move_data.gd` (5 por personaje, mezcla de comunes y exclusivos)
- [ ] T007 Crear archivos `.tres` para materiales de evolucion usando `material_data.gd` (Piedra Trueno, Piedra Fuego, Piedra Agua, etc.)

### Phase 2: Database Managers (Singletons)

**Purpose**: Autoloads que cargan los `.tres` Resources y proveen acceso rapido a los datos. Todas las queries son O(1) via diccionarios.

- [ ] T008 Crear `character_database.gd` — Autoload, carga todos los `.tres` de `resources/characters/` en diccionario `character_id → CharacterData`, metodos `get_character(id)`, `get_move_pool(character_id)`, `get_all_characters()`, `get_characters_by_identity(character_id)` (todos los CharacterData que comparten el mismo character_id, ej: prota_pikachu, prota_raichu)
- [ ] T009 Crear `move_database.gd` — Autoload, carga todos los `.tres` de `resources/moves/` en diccionario `move_id → MoveData`, metodos `get_move(id)`, `get_moves_for_character(character_id)`, `get_common_moves()` (movimientos no exclusivos)
- [ ] T010 Crear `evolution_manager.gd` — Autoload, metodos `check_evolution(character_instance) → Dictionary|null` (revisa `evolution_options` del CharacterData contra nivel actual e inventario de materiales), `get_available_evolutions(character_id, nivel, inventario_materiales) → Array[Dictionary]`

### Phase 3: Estado Runtime de Personajes

**Purpose**: Manejar el estado vivo de los personajes durante el juego: niveles, XP, evolucion pendiente, instancia activa.

- [ ] T011 Crear `character_instance.gd` — Clase que envuelve CharacterData con estado runtime: `current_character_id` (el id del CharacterData actual, cambia al evolucionar), `level: int`, `xp: int`, `evolution_history: Array[String]` (lista de character_ids por los que paso)
- [ ] T012 Implementar `character_instance.gain_xp(amount)` — Suma XP, verifica si alcanza nivel para evolucion (comparando con `evolution_options` del CharacterData actual), retorna `Dictionary` con la opcion de evolucion si aplica
- [ ] T013 Implementar `character_instance.evolve(dest_character_id: String)` — Cambia `current_character_id` al nuevo CharacterData, actualiza stats base desde el nuevo recurso, registra en `evolution_history`, retorna el nuevo `CharacterData`

### Phase 4: Composición y Gestión de Equipo

**Purpose**: Sistema de equipo de 3 personajes, selección y validación. Solo el protagonista rota criaturas.

- [ ] T014 Crear `team_state.gd` — Mantiene array[3] de CharacterData, índice de activo, metodos `add_member(character_data: CharacterData, slot: int)`, `remove_member(slot: int)`, `swap_character(slot: int, new_character_id: String)` (solo para protagonista, actualiza el CharacterData del slot)
- [ ] T015 Crear `character_roster.gd` — Registro de todos los CharacterData desbloqueados por el jugador, metodos `unlock(character_id: String)`, `get_unlocked() → Array[CharacterData]`, `is_unlocked(character_id: String) → bool`
- [ ] T016 Implementar validacion: no permitir equipo sin CharacterData asignado, no permitir swap_character en slots de no-protagonistas (excepto evolucion)

### Phase 5: UI de Personajes

**Purpose**: Pantallas de visualización y selección.

- [ ] T017 Crear `character_viewer.gd` + `.tscn` — Muestra sprite, stats, nivel, evoluciones disponibles, pool de movimientos de un CharacterData
- [ ] T018 Crear `evolution_screen.gd` + `.tscn` — Muestra opciones de evolucion ramificada (lee `evolution_options`) con previsualizacion de stats del destino, confirma seleccion
- [ ] T019 Crear `team_selector.gd` + `.tscn` — Grid de 3 slots, arrastrar personajes del roster al equipo

### Phase 6: Integración y Tests

- [ ] T020 Crear `test_character_scene.tscn` — Escena de prueba con character viewer, botones para subir nivel, trigger evolucion, seleccionar equipo
- [ ] T021 Validar que al evolucionar un personaje: (a) sprite cambia, (b) stats se actualizan, (c) pool de movimientos se expande con nuevos movimientos exclusivos
- [ ] T022 Validar que solo el protagonista puede rotar personaje y los demas personajes tienen identidad fija

## Dependencies

- **Bloquea**: `plan-gameplay-deckbuilder.md` (los mazos dependen del pool de movimientos de cada criatura)
- **Depende de**: Nada (es fundacional)
