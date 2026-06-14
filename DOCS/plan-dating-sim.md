# Implementation Plan: Sistema de Dating Sim / Relaciones

**Date**: 2026-06-12
**Spec**: `DOCS/spec-dating-sim.md`

## Summary

Implementar sistema de afinidad y relaciones entre el protagonista y personajes romanceables. Afinidad numérica (0-100) con 5 estados de relación (Desconocido → Amigo → Mejor Amigo → Interés Romántico → Enamorado). Sistema de confesión con reglas de Harem (default: 1 pareja, true: ilimitado) y Netori (default: personajes casados no romanceables, true: sí). Eventos de cita con recompensas. Afinidad negativa genera estado de "Enemistad". Al alcanzar "Enamorado" la afinidad no puede bajar.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `addons/sprouty_dialogs` (sistema de diálogos), `plan-overworld-exploration.md` (NPCs interactuables)
**Storage**: Estado de afinidades serializado en save file (JSON)
**Testing**: Test scenes in-editor con NPCs de prueba
**Target Platform**: Windows D3D12
**Performance Goals**: Cálculo de afinidad <1ms, UI de relaciones carga <100ms
**Constraints**: Hasta 20 personajes romanceables simultáneos sin degradación
**Scale/Scope**: ~15 personajes romanceables, 5 estados de relación, ~30 eventos de cita

## Project Structure

### Source Code (within `wip/`)

```text
src/dating/
├── state/
│   ├── affinity_manager.gd       # Singleton: CRUD de afinidades, estados, parejas
│   ├── relationship_state.gd     # Enum + lógica de estados de relación
│   ├── romance_config.gd         # Config de partida: Harem (bool), Netori (bool)
│   └── couple_registry.gd        # Registro de parejas actuales
├── dialogue/
│   ├── dialogue_option.gd        # Resource: opción de diálogo con modificador de afinidad
│   ├── dialogue_condition.gd     # Condiciones para mostrar opciones (estado, afinidad, flags)
│   └── affinity_reaction.gd      # Reacción de afinidad (+/- animación, feedback visual)
├── confession/
│   ├── confession_system.gd      # Lógica de confesión: validación de reglas, aceptación/rechazo
│   └── confession_scene.gd       # Escena de confesión (diálogo especial + decisión)
├── dates/
│   ├── date_manager.gd           # Trigger de eventos de cita por umbrales de afinidad
│   ├── date_event.gd             # Resource: datos de evento de cita (personaje, umbral, recompensas)
│   └── date_rewards.gd          # Lógica de recompensas (movimientos, objetos, bonus afinidad)
├── harem_netori/
│   ├── harem_handler.gd          # Lógica de harem: conflictos, celos, escenas grupales
│   └── netori_handler.gd         # Lógica de netori: interacción con cónyuges, confrontaciones
└── ui/
    ├── relationship_menu.gd      # Menú principal de relaciones (todos los personajes)
    ├── character_profile.gd      # Perfil individual: sprite, afinidad, estado, historia
    ├── affinity_bar.gd           # Componente: barra de afinidad animada
    ├── confession_ui.gd          # UI de confesión (opciones contextuales)
    └── harem_netori_toggle.gd    # Toggle en pantalla de nueva partida
```

## Phases

### Phase 1: Sistema de Afinidad (Fundacional)

**Purpose**: CRUD de afinidad por personaje, cálculo de estado de relación, persistencia.

- [ ] T001 Crear `affinity_manager.gd` — Autoload con diccionario `character_id → affinity_value` (int 0-100). Métodos: `get_affinity(character_id)`, `add_affinity(character_id, amount)`, `set_affinity(character_id, value)`
- [ ] T002 Implementar límites: afinidad clamp(0, 100). Si Harem=false y personaje ya es pareja, afinidad de otros se capa a 99 (no puede llegar a 100)
- [ ] T003 Crear `relationship_state.gd` — Enum: `UNKNOWN, FRIEND, BEST_FRIEND, ROMANTIC_INTEREST, IN_LOVE, ENMITY`. Umbrales configurables: 0=Unknown, 10=Friend, 30=BestFriend, 60=RomanticInterest, 100=InLove. ENMITY cuando afinidad <0
- [ ] T004 Implementar `affinity_manager.get_relationship_state(character_id) → RelationshipState` según umbrales
- [ ] T005 Implementar regla de afinidad negativa: permitir valores <0 con deuda. Método `subtract_affinity(character_id, amount)` que puede bajar a negativo. Si afinidad <0, estado = ENMITY
- [ ] T006 Implementar regla "Enamorado": cuando `relationship_state == IN_LOVE`, bloquear `subtract_affinity` (no baja más). Si Netori=true y personaje casado, sí puede bajar si el cónyuge se entera
- [ ] T007 Crear `romance_config.gd` — Resource: harem_enabled (bool, default false), netori_enabled (bool, default false). Se setea al inicio de partida, inmutable después
- [ ] T008 Implementar serialización: guardar `affinity_manager` + `romance_config` + `couple_registry` en save JSON

### Phase 2: Opciones de Diálogo Condicionales

**Purpose**: Diálogos que muestran opciones según afinidad y estado.

- [ ] T009 Crear `dialogue_option.gd` — Resource: texto, `affinity_modifier` (int, puede ser negativo), `required_state` (RelationshipState o null), `required_flags` (dict[flag→bool])
- [ ] T010 Crear `dialogue_condition.gd` — Evalúa si una opción es visible: `check_condition(option, character_id, affinity_manager, flags)`
- [ ] T011 Integrar con sprouty_dialogs: hook en `dialogue_node.gd` o `event_interpreter.gd` para inyectar opciones condicionales según afinidad
- [ ] T012 Implementar `affinity_reaction.gd` — Al elegir opción: animación de +corazón o -corazón flotante sobre el personaje, sonido, particle effect

### Phase 3: Sistema de Confesión

**Purpose**: Lógica de confesión con reglas de Harem y Netori.

- [ ] T013 Crear `confession_system.gd` — Método `can_confess(character_id, romance_config) → ConfessionResult`:
  - Si character.civil_status == MARRIED && !netori_enabled → REJECTED_MARRIED
  - Si !harem_enabled && couple_registry.has_partner() && character_id != current_partner → REJECTED_HAREM
  - Si affinity < 100 → NOT_ENOUGH_AFFINITY
  - Si está todo OK → ACCEPTED
- [ ] T014 Crear `couple_registry.gd` — Mantiene lista de parejas actuales. Si harem_enabled, permite múltiples. Métodos: `add_partner(character_id)`, `remove_partner(character_id)`, `has_partner()`, `get_partners()`
- [ ] T015 Implementar respuesta a confesión: si aceptada → couple_registry.add_partner(), evento de historia, desbloqueo de escenas. Si rechazada → diálogo de rechazo contextual (motivo específico)
- [ ] T016 Crear `confession_scene.gd` — Escena visual de confesión: fondos, sprites, diálogo especial, decisión del jugador (confesarse o no)

### Phase 4: Harem y Netori Handlers

**Purpose**: Lógica de escenas complejas entre personajes del harem y confrontaciones de netori.

- [ ] T017 Crear `harem_handler.gd` — Detecta situaciones de harem: múltiples parejas en misma escena → activa diálogos de celos, conflicto o alianza según personalidades. Flags de historia para resolver conflictos
- [ ] T018 Crear `netori_handler.gd` — Si netori_enabled y personaje casado en relación:
  - Probabilidad de que el cónyuge "se entere" (basado en flags y eventos)
  - Si se entera → escena de confrontación con el cónyuge
  - Posibles outcomes: pelea, ruptura forzada, aceptación renuente
- [ ] T019 Integrar con `dialogue_condition.gd`: flags de harem/netori afectan opciones de diálogo disponibles

### Phase 5: Eventos de Cita

**Purpose**: Escenas de cita desbloqueadas por umbrales de afinidad con recompensas.

- [ ] T020 Crear `date_event.gd` — Resource: character_id, affinity_threshold, scene_path, rewards (move_id, item_id, affinity_bonus, flags_set), one_shot (bool)
- [ ] T021 Crear `date_manager.gd` — Monitorea `affinity_manager` por cambios. Al cruzar umbral → verifica si `date_event` pendiente → dispara escena de cita
- [ ] T022 Implementar `date_rewards.gd` — Al completar cita: otorga recompensa (movimiento especial de la criatura del personaje), bonus de afinidad, desbloquea flags
- [ ] T023 Citas en modo Netori: variantes de diálogo que reflejan el secreto/riesgo, posibilidad de ser descubierto

### Phase 6: Interacción con Otros Sistemas

**Purpose**: Conexiones con combate y overworld.

- [ ] T024 Afinidad → stats en combate: si personaje es compañero de equipo, cada nivel de relación otorga +5 Defensa (u otros bonuses). Implementar en `pokemon_battle_state.gd` al inicializar combate
- [ ] T025 Indicador visual en overworld: modificar `interaction_prompt.gd` para mostrar icono de afinidad (corazón vacío/medio/lleno) + estado de relación junto al prompt del NPC
- [ ] T026 Bloquear afinidad de personajes muertos: si flag de historia `CHARACTER_X_DEAD` está activo, `affinity_manager` rechaza cambios de afinidad para ese personaje

### Phase 7: UI de Relaciones

**Purpose**: Pantallas de visualización de afinidad y relaciones.

- [ ] T027 Crear `relationship_menu.gd` + `.tscn` — Grid/tab de todos los personajes conocidos con: sprite, nombre, barra de afinidad, estado actual (etiqueta), indicador de pareja (corazón)
- [ ] T028 Crear `character_profile.gd` — Vista detallada de un personaje: sprite grande, afinidad numérica, historial de eventos de relación, criatura asociada, estado civil
- [ ] T029 Crear `affinity_bar.gd` — Componente reutilizable: barra horizontal animada (0-100) con marcas en umbrales de estado, color según estado actual
- [ ] T030 Crear `harem_netori_toggle.gd` — UI en pantalla de Nueva Partida: dos toggles con tooltips explicativos, default ambos en false

### Phase 8: Integración con NG+ y Roguelike

**Purpose**: Comportamiento del sistema de relaciones en transiciones de modo.

- [ ] T031 En NG+: resetear todas las afinidades a 0, vaciar couple_registry, conservar romance_config del perfil
- [ ] T032 En Roguelike: las afinidades NO se modifican al entrar/salir de runs. El sistema de afinidad permanece congelado durante Roguelike

## Dependencies

- **Depende de**: `plan-overworld-exploration.md` (NPCs), `addons/sprouty_dialogs` (diálogos), `plan-creature-integration.md` (criaturas de personajes)
- **Bloquea**: `plan-meta-progression.md` (NG+ resetea afinidades)
