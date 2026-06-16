# Implementation Plan: Sistema de Furor y Mecánicas Especiales

**Date**: 2026-06-14
**Spec**: `DOCS/specs/spec-furor-system.md`

## Summary

Implementar la barra de Furor (0-10) como recurso compartido del equipo en combate, y las cuatro mecánicas especiales que consumen furor: Mega Evolución, Movimiento Z, Gigantamax/Dynamax y Teracrestalización. El furor se acumula al realizar acciones (atacar, recibir daño, curar, debilitar enemigos) y se gasta al activar mecánicas. Las mecánicas se desbloquean progresivamente mediante flags de historia.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `plan-creature-integration.md` (datos de Pokémon para formas alternativas), `plan-gameplay-deckbuilder.md` (sistema de combate base)
**Storage**: Estado de furor en memoria durante combate; flags de desbloqueo persistidos en save file
**Testing**: Test scenes in-editor
**Target Platform**: Windows D3D12
**Performance Goals**: Actualización de barra de furor <50ms, resolución de mecánica combinada <200ms
**Constraints**: Las mecánicas deben ser modulares (fácil añadir/quitar/modificar costes y efectos)
**Scale/Scope**: 1 barra de furor, 4 mecánicas especiales, 4 flags de desbloqueo

## Project Structure

### Source Code (within `wip/`)

```text
src/combat/
├── furor/
│   ├── furor_bar.gd             # Barra de furor (0-10): acumulación, gasto, reset
│   ├── furor_bar_ui.gd          # Visualización de la barra de furor en el HUD
│   ├── mechanic_resolver.gd     # Resuelve mecánicas especiales (Mega, Z-Move, G-Max, Tera)
│   └── mechanic_panel_ui.gd     # Panel de selección de mecánicas en combate (disponibles/bloqueadas)
```

## Clean Code Guidelines

### Naming & Style
- **Clases**: `PascalCase` — `FurorBar`, `MechanicResolver`, `MechanicUnlockState`
- **Variables/métodos**: `snake_case` — `current_furor`, `can_afford()`, `spend_furor()`
- **Constantes**: `UPPER_SNAKE_CASE` — `MAX_FUROR = 10`, `MEGA_COST = 4`, `Z_MOVE_COST = 2`
- **Señales**: `snake_case` en pasado — `furor_changed`, `mechanic_activated`, `mechanic_deactivated`

### Single Responsibility
- **FurorBar** (`furor_bar.gd`): Solo recurso numérico (0-10); no conoce mecánicas ni UI
- **MechanicResolver** (`mechanic_resolver.gd`): Solo registro y activación de mecánicas; no maneja UI
- **UI** (`furor_bar_ui.gd`, `mechanic_panel_ui.gd`): Solo presentación; observan FurorBar y MechanicResolver
- Cada mecánica (Mega, Z-Move, G-Max, Tera) debe ser un Resource independiente, no un switch gigante

### Métodos
- `add_furor()` con clamping en una línea: `current_furor = min(max_furor, current_furor + amount)`
- **Guard clauses**: `if not can_afford(cost): signal_bus.emit("furor_insufficient"); return`
- `activate_mechanic()` debe delegar el efecto a la subclase/Resource de la mecánica específica
- `spend_furor()` y `add_furor()` siempre emiten `furor_changed` al final para notificar UI

### Godot-Specific
- `FurorBar` como Node en la escena de combate (no Autoload — se recrea por combate)
- `MechanicResolver` como Node hermano de `FurorBar` en la escena de combate
- `MechanicUnlockState` persistido en save file; cargado al iniciar combate
- `@export var furor_sources: Dictionary` — hook actions → furor gain, configurable desde editor
- Señal `SignalBus.furor_changed.emit(current, max)` para que UI, partículas y SFX reaccionen

### Valores configurables
- Costes de furor por mecánica (`MEGA_COST = 4`) en constantes o `@export`, nunca hardcodeados
- Generación de furor por tipo de acción en diccionario `furor_sources` exportable
- Bonificadores de stats de G-Max, multiplicador de Z-Move como `@export var z_move_multiplier: float = 2.5`

---

## Phases

### Phase 1: Barra de Furor (Fundacional)

**Purpose**: Implementar la barra de furor como recurso y su integración con el HUD de combate.

- [ ] T001 Crear `furor_bar.gd` — Clase con: `current_furor` (int 0-10), `add_furor(amount)`, `can_afford(cost) → bool`, `spend_furor(cost)`, `reset()`
- [ ] T002 Implementar `add_furor(amount)` con clamping a [0, 10]; el exceso se descarta silenciosamente
- [ ] T003 Implementar hooks de generación de furor en el sistema de combate:
  - +1 al usar movimiento de ataque (hook en `move_resolver.gd`)
  - +2 al recibir daño (hook en `pokemon_battle_state.take_damage`)
  - +1 al curarse (hook en resolución de movimientos de curación)
  - +3 al debilitar un Pokémon enemigo (hook en resolución de KO)
  - Valores configurables por tipo de acción (constant o recurso)
- [ ] T004 Crear `furor_bar_ui.gd` — Barra visual: fondo oscuro, segmentos que se llenan con gradiente (vacío → azul → dorado al máximo), animación de shake al recibir daño, animación de drenaje al gastar, tooltip con valor numérico exacto
- [ ] T005 Probar en escena de test: generar furor con cada tipo de acción, verificar clamping a 10, verificar reset entre combates

---

### Phase 2: Sistema de Mecánicas (Core)

**Purpose**: Implementar el resolver de mecánicas y su integración con el flujo de combate.

- [ ] T006 Crear `mechanic_resolver.gd` — Singleton que gestiona el registro de mecánicas. Métodos: `register_mechanic(data)`, `get_available_mechanics(pokemon) → Array`, `activate_mechanic(id, pokemon, context)`, `deactivate_mechanic(id, pokemon)`
- [ ] T007 Definir estructura de datos de cada mecánica como recurso (`.tres` o diccionario):

  | Mecánica | Coste | Efecto | Duración |
  |---|---|---|---|
  | Mega Evolución | 4 | Cambia sprite, stats, mazo del Pokémon a versión mega | Todo el combate |
  | Movimiento Z | 2 | Multiplica daño del siguiente movimiento ×2.5 | Un movimiento |
  | Gigantamax/Dynamax | 5 | +50% HP máx, bonus stats (+20% ATK, +20% DEF) | 3 turnos |
  | Teracrestalización | 3 | Cambia tipo elemental, bonus STAB ×1.5 adicional | Todo el combate |

- [ ] T008 Implementar `activate_mechanic()`: verifica `can_afford()`, gasta furor, aplica efecto según tipo de mecánica, registra `ActiveMechanic` en el Pokémon
- [ ] T009 Implementar efectos por mecánica:
  - **Mega Evolución**: `pokemon.set_mega_form(mega_form_data)` — reemplaza sprite, stats y referencia al mazo mega
  - **Movimiento Z**: `next_move_damage_multiplier = 2.5` — se consume al resolver el siguiente movimiento del Pokémon
  - **Gigantamax/Dynamax**: `pokemon.max_hp *= 1.5`, `pokemon.hp = pokemon.max_hp` (llena HP), `pokemon.atk *= 1.2`, `pokemon.def *= 1.2`, `turns_remaining = 3`
  - **Teracrestalización**: `pokemon.tera_type = chosen_type`, `pokemon.stab_bonus += 0.5` (se suma al ×1.5 base de STAB)
- [ ] T010 Implementar `deactivate_mechanic()` para G-Max al expirar: revierte HP máximo (HP actual se escala proporcionalmente), revierte stats, elimina `ActiveMechanic`
- [ ] T011 Implementar ciclo de turno para G-Max: al inicio de cada turno del jugador, `turns_remaining -= 1`; si llega a 0, se desactiva automáticamente

---

### Phase 3: Combinación de Mecánicas

**Purpose**: Permitir activar múltiples mecánicas antes de resolver un movimiento.

- [ ] T012 Crear `pending_mechanics` (stack) en `mechanic_resolver.gd` — Almacena IDs de mecánicas activadas pero aún no resueltas
- [ ] T013 Implementar flujo de combinación:
  1. Jugador selecciona un movimiento
  2. Antes de resolver, puede activar mecánicas (Z-Move, Tera) en cualquier orden
  3. Cada activación añade al stack `pending_mechanics` y descuenta furor
  4. Al confirmar, las mecánicas se aplican en orden de stack (FIFO) sobre el movimiento
  5. Si el furor se agota a medio stack, se revierten las activaciones parciales
- [ ] T014 Implementar multiplicación de efectos cuando múltiples mecánicas afectan el mismo stat (ej: G-Max +20% ATK × Z-Move ×2.5 daño = ×3.0 daño total)
- [ ] T015 Probar combinaciones en escena de test: Mega + Z-Move, Mega + Tera, Mega + Tera + Z-Move, G-Max + Z-Move, etc.

---

### Phase 4: Desbloqueo por Historia

**Purpose**: Sistema de flags de desbloqueo y su integración con la historia y Roguelike.

- [ ] T016 Crear `MechanicUnlockState` como recurso singleton global: `mega_unlocked`, `z_moves_unlocked`, `gmax_unlocked`, `tera_unlocked` (todos bool, default false)
- [ ] T017 Implementar `unlock_mechanic(flag_name)` — Activa el flag correspondiente. Se llama desde eventos de historia (señal `story_event_completed`)
- [ ] T018 Crear `mechanic_panel_ui.gd` — Panel en el HUD de combate que muestra:
  - Mecánicas disponibles: botón con nombre + coste, iluminado, cliqueable
  - Mecánicas bloqueadas: botón en gris con icono de candado, tooltip "Disponible más adelante en la historia"
  - Mecánicas no compatibles con el Pokémon actual: botón atenuado, tooltip "[Pokémon] no puede usar esta mecánica"
- [ ] T019 Filtrar mecánicas en `get_available_mechanics(pokemon)` según: (a) flag de desbloqueo activo, (b) compatibilidad del Pokémon (tiene forma mega/G-Max/Tera definida)
- [ ] T020 Persistir `MechanicUnlockState` en el save file (junto con el resto del estado de historia)
- [ ] T021 En Roguelike, al iniciar la run: cargar `MechanicUnlockState` del save file de historia; las mecánicas no desbloqueadas no aparecen como opción

---

### Phase 5: UI y Feedback

**Purpose**: Pulido visual y auditivo del sistema de furor y mecánicas.

- [ ] T022 Animación de la barra de furor: llenado suave (lerp), shake al recibir daño, drenaje rápido al gastar, glow dorado al llegar a 10
- [ ] T023 Partículas y efectos visuales al activar cada mecánica:
  - Mega Evolución: espiral de energía + transformación
  - Movimiento Z: aura brillante + pose del entrenador
  - Gigantamax: crecimiento del sprite + nube de energía roja
  - Teracrestalización: cristalización + destello del tipo Tera
- [ ] T024 Sonidos: SFX de acumulación de furor, SFX distinto por cada mecánica al activarse, SFX de "furor insuficiente" (error)
- [ ] T025 Tooltips detallados en hover sobre cada mecánica: nombre, descripción del efecto, coste de furor, duración, compatibilidad

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies — fundacional, bloquea todo
- **Phase 2**: Depende de Phase 1 (necesita `furor_bar.gd` para `can_afford` y `spend_furor`)
- **Phase 3**: Depende de Phase 2 (necesita mecánicas individuales funcionales para combinarlas)
- **Phase 4**: Depende de Phase 2 (necesita mecánicas registradas para filtrar por flags). Puede hacerse en paralelo con Phase 3.
- **Phase 5**: Depende de Phase 2-4 (necesita todas las mecánicas y UI base funcional)

### Dependencias Externas

- **Depende de**: `plan-gameplay-deckbuilder.md` (sistema de combate base: hooks de acciones, flujo de turno, HUD)
- **Depende de**: `plan-creature-integration.md` (datos de formas alternativas: mega, G-Max, Tera)
- **Referenciado por**: `plan-gameplay-deckbuilder.md` (el HUD de combate integra la barra de furor y el panel de mecánicas)
