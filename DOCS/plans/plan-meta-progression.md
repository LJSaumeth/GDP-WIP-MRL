# Implementation Plan: Progresión entre Runs (Historia + Roguelike)

**Date**: 2026-06-12
**Spec**: `DOCS/spec-meta-progression.md`

## Summary

Implementar el flujo principal del juego: Modo Historia lineal con capítulos, desde el cual se accede al Modo Roguelike (Liga Pokémon). El Roguelike no es un modo separado en el menú principal, sino una actividad accesible desde locaciones en el overworld de la historia (ej. Arenas de Combate). Sistema de meta-progresión con Legacy Points ganados en runs, desbloqueos permanentes compartidos entre perfiles. Soporte para NG+, Ascensión de 20 niveles de dificultad, y 3 perfiles de guardado independientes.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Todos los planes anteriores. `plan-creature-integration.md`, `plan-gameplay-deckbuilder.md`, `plan-overworld-exploration.md`, `plan-dating-sim.md`
**Storage**: Save files usando Godot Resources (3 perfiles), meta-progresion en Resource compartido
**Testing**: Test scenes in-editor + playthroughs manuales
**Target Platform**: Windows D3D12
**Performance Goals**: Carga de save <1s, generación de mapa Roguelike <500ms, transición historia↔Roguelike <3s
**Constraints**: No perder progreso en crash, meta-progresión atómica, 3 perfiles máximo
**Scale/Scope**: ~20 capítulos de historia, 3 actos por run Roguelike, 20 niveles de Ascensión, ~50 desbloqueables

## Project Structure

### Source Code (within `wip/`)

```text
src/progression/
├── story/
│   ├── story_manager.gd          # Singleton: control de capítulos, flags, progreso
│   ├── chapter_data.gd           # Resource: datos de capítulo (zonas, combates fijos, cutscenes)
│   ├── story_flags.gd            # Gestión de flags de historia (diccionario global)
│   └── cutscene_player.gd        # Secuenciador de cutscenes (diálogos, animaciones, eventos)
├── roguelike_access/
│   ├── roguelike_gateway.gd      # Punto de acceso desde overworld a Roguelike
│   └── roguelike_exit_node.gd    # Nodo de salida en mapa Roguelike (cada X pisos)
├── meta/
│   ├── meta_progress.gd          # Singleton: Legacy Points, desbloqueos, Ascensión
│   ├── unlock_tree.gd            # Árbol de desbloqueos (grafo de dependencias)
│   └── meta_shop_ui.gd           # UI de tienda de meta-progresión
├── save/
│   ├── save_manager.gd           # Singleton: carga/guarda perfiles de guardado
│   ├── save_data.gd              # Resource: estructura de un save file
│   ├── profile_manager.gd        # Gestión de 3 perfiles (crear, borrar, seleccionar)
│   └── save_migration.gd         # Migración de saves entre versiones
├── ascension/
│   ├── ascension_manager.gd      # Lógica de niveles de Ascensión (1-20)
│   └── ascension_modifiers.gd    # Modificadores por nivel (más enemigos, menos curaciones, etc.)
├── ng_plus/
│   ├── ng_plus_handler.gd        # Lógica de NG+: reset historia, conservar meta-progresión
│   └── ng_plus_transition.gd     # Escena de transición a NG+
└── ui/
    ├── main_menu.gd              # Menú principal: Nueva Partida, Cargar, NG+, Config
    ├── profile_select.gd         # Selector de perfil (3 slots)
    ├── new_game_config.gd        # Config inicial: nombre, Harem, Netori
    ├── pause_menu.gd             # Menú de pausa: guardar, cargar, salir
    └── meta_progress_ui.gd       # Pantalla de progreso: puntos, desbloqueos, Ascensión
```

## Clean Code Guidelines

### Naming & Style
- **Clases**: `PascalCase` — `SaveManager`, `StoryManager`, `MetaProgress`, `NGPlusHandler`
- **Variables/métodos**: `snake_case` — `current_chapter`, `legacy_points`, `save()`, `load()`
- **Constantes**: `UPPER_SNAKE_CASE` — `MAX_PROFILES = 3`, `MAX_ASCENSION = 20`
- **Señales**: `snake_case` en pasado — `game_saved`, `chapter_completed`, `run_finished`
- **Flags de historia**: `snake_case` — `MET_MISTY`, `BEAT_GYM_1`, `MEGA_UNLOCKED`

### Single Responsibility
- **Save** (`save/`): Solo serialización/deserialización; sin lógica de juego
- **Story** (`story/`): Solo progresión de capítulos y flags; sin UI
- **Meta** (`meta/`): Solo Legacy Points y desbloqueos; independiente de perfiles
- **NG+** (`ng_plus/`): Solo reseteo de estado; delegar a cada manager su propio reset
- `save_manager` no debe conocer detalles de `affinity_manager` — cada sistema serializa su propia data

### Métodos
- `save()` debe ser atómico: juntar data de todos los sistemas, serializar, escribir — sin pasos intermedios
- **Guard clauses**: `if profile_id >= MAX_PROFILES: push_error("…"); return` al inicio
- `save_migration.gd` debe ser una cadena de transformaciones (`v1→v2`, `v2→v3`) independientes
- Métodos de cálculo de Legacy Points extraídos a `_calculate_base_score()`, `_apply_multipliers()`

### Godot-Specific
- `save_manager` como Autoload para acceso global
- `story_manager` como Autoload — único punto de verdad para progreso de historia
- `@export var auto_save_on_zone_change: bool = true` para comportamiento configurable
- Señal `SignalBus.save_requested.emit()` → cada sistema responde con su dictionary de datos
- Usar `ConfigFile` o Resource con serializacion via `inst_to_dict`/`dict_to_inst` para persistencia; wrapper en helper para testing

### Manejo de errores
- `save()` y `load()` con try/catch o validación de retorno; nunca crashear por save corrupto
- Si un save falla al cargar: mostrar error descriptivo, no cargar estado parcial
- `save_migration` con logs de qué versión se migró y resultado

## Phases

### Phase 1: Gestión de Guardado (Fundacional)

**Purpose**: Sistema de perfiles y guardado que todo lo demás necesita.

- [ ] T001 Crear `save_data.gd` — Resource con toda la data serializable de una partida:
  - story_progress: capítulo, zona, flags, personajes_conocidos
  - team_state: 3 CharacterData actuales
  - affinity_data: todas las afinidades y parejas
  - inventory: Pokédólares, objetos, materiales de evolución
  - romance_config: harem, netori
  - roguelike_run: estado de run pausada (opcional)
- [ ] T002 Crear `save_manager.gd` — Autoload. Métodos: `save(profile_id)`, `load(profile_id) → SaveData`, `delete(profile_id)`, `get_all_profiles() → Array`
- [ ] T003 Implementar serializacion de `SaveData`: usar `inst_to_dict` para Resources, `dict_to_inst` para cargar
- [ ] T004 Crear `profile_manager.gd` — UI para crear/borrar/seleccionar perfiles. Máximo 3 perfiles. Muestra: nombre, capítulo actual, tiempo jugado, fecha último guardado
- [ ] T005 Implementar auto-guardado: al cambiar de zona, al completar combate, al entrar/salir de Roguelike (solo entre nodos, no mid-combate)
- [ ] T006 Crear `save_migration.gd` — Detectar versión de save, migrar campos si cambia la estructura en updates futuros

### Phase 2: Modo Historia - Capítulos

**Purpose**: Estructura de progresión lineal por capítulos.

- [ ] T007 Crear `story_manager.gd` — Autoload. Controla: capítulo actual, sub-estado del capítulo, triggers de eventos. Métodos: `start_chapter(chapter_id)`, `complete_chapter()`, `get_current_chapter()`
- [ ] T008 Crear `chapter_data.gd` — Resource: chapter_id, display_name, zonas (array de zone_ids en orden), combates_fijos (array de encounter_ids), cutscenes (array de cutscene_paths), requisito_anterior
- [ ] T009 Crear `story_flags.gd` — Diccionario global `flag_name → bool`. Métodos: `set_flag(name)`, `has_flag(name)`, `clear_flag(name)`. Flags persisten en save
- [ ] T010 Implementar progresión lineal: al completar zona final de capítulo → trigger evento de cierre → desbloquear siguiente capítulo
- [ ] T011 Bloquear zonas por flag: `transition_trigger` verifica `story_flags.has_flag(required_flag)` antes de permitir transición

### Phase 3: Cutscenes y Eventos de Historia

**Purpose**: Sistema de secuencias narrativas.

- [ ] T012 Crear `cutscene_player.gd` — Secuenciador de eventos: dialogos, movimientos de camara, animaciones de sprites, sonidos. Lee archivos de cutscene (`.tres` con secuencia de comandos)
- [ ] T013 Integrar con `addons/sprouty_dialogs` para cutscenes de diálogo: cargar diálogos desde el sistema de sprouty
- [ ] T014 Eventos de historia que disparan cambios de criatura del protagonista: trigger → `creature_instance.evolve()` o `team_state.swap_creature()`

### Phase 4: Acceso a Roguelike desde la Historia

**Purpose**: Puntos de entrada al modo Roguelike dentro del overworld.

- [ ] T015 Crear `roguelike_gateway.gd` — Interactable especial en overworld (ej. edificio "Arena de Combate", "Liga Pokémon"). Al interactuar:
  1. Verifica que el jugador tenga al menos 1 personaje desbloqueado para Roguelike
  2. Guarda estado actual de historia (zona, posición)
  3. Transiciona a `map_scene.tscn` (mapa de la Liga)
- [ ] T016 Implementar retorno a historia desde Roguelike:
  - Al morir/completar run: volver a `roguelike_gateway` de origen, restaurar estado de historia
  - Nodo de salida en mapa: mismo comportamiento pero run se pausa (guardar estado de run en save)
- [ ] T017 Bloquear acceso a Roguelike si no hay personajes desbloqueados (mostrar mensaje: "Necesitas conocer al menos 1 personaje en la historia")

### Phase 5: Meta-Progresión

**Purpose**: Sistema de Legacy Points y desbloqueos permanentes.

- [ ] T018 Crear `meta_progress.gd` — Autoload que persiste en archivo separado (no por perfil, compartido). Atributos:
  - `legacy_points` (int)
  - `unlocked_cards` (array de move_ids)
  - `unlocked_relics` (array de item_ids)
  - `unlocked_characters` (array de character_ids)
  - `max_ascension_level` (int 0-20)
- [ ] T019 Implementar ganancia de Legacy Points al finalizar run: fórmula basada en `acto_alcanzado * 10 + enemigos_derrotados * 2 + cartas_en_mazo * 1`
- [ ] T020 Crear `unlock_tree.gd` — Define dependencias de desbloqueo: ciertos personajes/cartas requieren desbloqueos previos. Método: `can_unlock(unlock_id) → bool`
- [ ] T021 Crear `meta_shop_ui.gd` + `.tscn` — Tienda visual de meta-progresión. Categorías: Personajes, Cartas, Reliquias, Ascensión. Muestra coste, previsualización, botón comprar
- [ ] T022 Implementar que los desbloqueos de meta-progresión se reflejan inmediatamente en Roguelike (siguiente run)

### Phase 6: Sistema de Ascensión

**Purpose**: 20 niveles de dificultad incremental para Roguelike.

- [ ] T023 Crear `ascension_manager.gd` — Define modificadores por nivel de Ascensión (1-20):
  - Nivel 1: enemigos +10% HP
  - Nivel 5: menos curaciones en Centro Pokémon
  - Nivel 10: enemigos élite más frecuentes
  - Nivel 15: jefes tienen nueva fase
  - Nivel 20: muerte permanente de Pokémon en la run
- [ ] T024 Crear `ascension_modifiers.gd` — Resource con todos los modificadores por nivel. Aplicar al iniciar nueva run según `meta_progress.max_ascension_level`
- [ ] T025 UI de selección de Ascensión: al iniciar run, mostrar nivel actual (1-20), permitir elegir nivel si hay múltiples desbloqueados

### Phase 7: Nueva Partida+

**Purpose**: NG+ que conserva meta-progresión pero reinicia historia.

- [ ] T026 Crear `ng_plus_handler.gd` — Al completar historia (derrotar jefe final / último capítulo), desbloquear opción NG+ en menú principal. Al iniciar NG+:
  - Reiniciar `story_progress` a capítulo 1
  - Resetear `affinity_data` (todas afinidades a 0)
  - Resetear `team_state` (protagonista con criatura inicial)
  - Resetear `inventory`
  - Conservar `meta_progress` (Legacy Points, desbloqueos)
  - Conservar `romance_config`
- [ ] T027 Crear `ng_plus_transition.gd` — Escena de transición: resumen de lo conservado, confirmación, animación
- [ ] T028 Verificar que personajes desbloqueados en run anterior siguen disponibles en Roguelike durante NG+

### Phase 8: Desbloqueos por Historia → Roguelike

**Purpose**: Conocer personajes en la historia los desbloquea para Roguelike.

- [ ] T029 Al completar capítulo donde se conoce a un personaje: `meta_progress.unlocked_characters.append(character_id)`
- [ ] T030 Verificar que solo personajes desbloqueados (vía historia O meta-progresión) aparecen como seleccionables al iniciar run Roguelike
- [ ] T031 Eventos de historia que desbloquean mecánicas especiales: setear flags `MEGA_UNLOCKED`, `Z_MOVES_UNLOCKED`, `GMAX_UNLOCKED`, `TERA_UNLOCKED` en `story_flags` → disponibles en Roguelike

### Phase 9: UI de Menús

**Purpose**: Menú principal, pausa, y navegación entre modos.

- [ ] T032 Crear `main_menu.gd` + `.tscn` — Opciones: Nueva Partida, Cargar Partida, Nueva Partida+ (si desbloqueada), Configuración, Salir
- [ ] T033 Crear `new_game_config.gd` — Tras seleccionar "Nueva Partida": input nombre, toggles Harem/Netori (default false), botón Iniciar
- [ ] T034 Crear `pause_menu.gd` — Accesible desde overworld: Guardar, Cargar, Equipo, Relaciones, Configuración, Salir al Menú
- [ ] T035 Crear `meta_progress_ui.gd` — Accesible desde menú principal y pausa. Muestra: Legacy Points totales, progreso de desbloqueos, nivel de Ascensión

### Phase 10: Flujo Completo Integrado

**Purpose**: Conectar todos los sistemas en el flujo de juego completo.

- [ ] T036 Flujo Nueva Partida: Main Menu → New Game Config → Capítulo 1 inicia → overworld + diálogos → combates fijos
- [ ] T037 Flujo Roguelike: overworld → Roguelike Gateway → Map Scene → combate → recompensa → mapa → ... → fin de run → retorno a overworld
- [ ] T038 Flujo NG+: Main Menu → NG+ (si desbloqueado) → confirmación → Capítulo 1 (conservando meta-progresión)
- [ ] T039 Flujo Muerte en Roguelike: derrota → run summary → cálculo Legacy Points → retorno a overworld de origen
- [ ] T040 Flujo Carga: Main Menu → Cargar → Profile Select → cargar save → restaurar posición exacta en overworld

## Dependencies

- **Depende de**: Todos los demás planes (`creature-integration`, `gameplay-deckbuilder`, `overworld-exploration`, `dating-sim`)
- **Es el integrador final**: une todos los sistemas en el flujo de juego completo
