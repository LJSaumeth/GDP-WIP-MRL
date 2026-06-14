# Implementation Plan: Deckbuilder Roguelike - Combate Pokémon

**Date**: 2026-06-12
**Spec**: `DOCS/spec-gameplay-deckbuilder.md`

## Summary

Implementar el sistema de combate por turnos estilo deckbuilder (Slay the Spire) con temática Pokémon. El jugador (entrenador) controla un equipo de 1-3 Pokémon, cada uno con su propio mazo de movimientos. Ciclo: turno del jugador (usar movimientos gastando energía) → turno del enemigo (ejecuta intención visible). Sistema de Furor para mecánicas especiales. Mapa de Liga con nodos entre combates.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `plan-creature-integration.md` (pools de movimientos), Godot Control nodes para UI
**Storage**: Estado de combate en memoria, estado de run serializado a JSON para persistencia
**Testing**: Test scenes in-editor
**Target Platform**: Windows D3D12
**Performance Goals**: <16ms por frame, resolución de movimientos <200ms, animaciones fluidas
**Constraints**: UI responsive, soporte para hasta 20 movimientos en mano simultáneos sin lag
**Scale/Scope**: 3 actos por run, ~50 movimientos en pool total, 4 mecánicas especiales

## Project Structure

### Source Code (within `wip/`)

```text
src/combat/
├── battle_scene.tscn            # Escena principal de combate
├── state/
│   ├── battle_state.gd          # Estado global del combate (turno, fase, resultado)
│   ├── pokemon_battle_state.gd  # Estado de un Pokémon en combate (HP, Defensa, buffs/debuffs, estados)
│   ├── deck_state.gd            # Gestión de mazo: drawPile, hand, discardPile
│   ├── furor_bar.gd             # Barra de furor (0-10), acumulación y consumo
│   └── enemy_ai.gd              # IA enemiga (patrones de intención)
├── actions/
│   ├── move_resolver.gd         # Resuelve un movimiento: daño, Defensa, estados, efectos
│   ├── status_handler.gd        # Aplica y resuelve estados alterados (turno a turno)
│   └── mechanic_resolver.gd     # Resuelve mecánicas especiales (Mega, Z-Move, G-Max, Tera)
├── ui/
│   ├── battle_hud.gd            # HUD principal: HP, energía, furor, botón terminar turno
│   ├── hand_display.gd          # Muestra la mano de movimientos del Pokémon activo
│   ├── move_card.gd             # Componente: carta individual de movimiento
│   ├── intent_display.gd        # Muestra la intención del enemigo
│   ├── pokemon_info_panel.gd    # Panel lateral con stats del Pokémon activo
│   ├── target_selector.gd       # UI para seleccionar objetivo enemigo
│   └── furor_bar_ui.gd          # Visualización de la barra de furor
├── map/
│   ├── map_scene.tscn           # Escena del mapa de la Liga
│   ├── map_generator.gd         # Generación procedural del mapa (3 actos)
│   ├── map_node.gd              # Componente: nodo individual del mapa
│   ├── map_path_renderer.gd     # Dibuja conexiones entre nodos
│   └── map_camera.gd            # Cámara y navegación del mapa
├── rewards/
│   ├── reward_screen.gd         # Pantalla de recompensa post-combate (3 movimientos)
│   └── run_summary.gd           # Pantalla de resumen al finalizar run
└── shop/
    ├── shop_scene.tscn          # Tienda Pokémon
    └── shop_manager.gd          # Lógica de compra/venta/eliminar movimientos
```

## Phases

### Phase 1: Core del Mazo y Mano (Fundacional)

**Purpose**: Implementar las estructuras de datos del mazo (draw/discard/hand) sin UI de combate aún. Esto es el núcleo que todo lo demás necesita.

- [ ] T001 Crear `deck_state.gd` — Clase que gestiona tres arrays: `draw_pile`, `hand`, `discard_pile`. Métodos: `shuffle()`, `draw(n)`, `discard(card_index)`, `discard_hand()`, `reshuffle_discard_into_draw()`
- [ ] T002 Implementar `deck_state.initialize(creature_data)` — Crea mazo inicial desde el pool de movimientos de la criatura (movimientos básicos + exclusivos iniciales)
- [ ] T003 Implementar `deck_state.add_move(move_id)` — Añade un movimiento al mazo (post-recompensa)
- [ ] T004 Implementar `deck_state.remove_move(move_index)` — Elimina un movimiento del mazo (tienda)
- [ ] T005 Test unitario en escena de prueba: crear mazo, robar 5 cartas, descartar 2, verificar pilas

### Phase 2: Estado de Combate

**Purpose**: Estado del Pokémon en combate (HP, Defensa, buffs/debuffs) y estado global del combate.

- [ ] T006 Crear `pokemon_battle_state.gd` — Wrapper de CreatureInstance con estado de combate: hp_actual, defensa_actual, buffs (dict[stat→value]), debuffs (dict[stat→value]), status_condition, deck_state
- [ ] T007 Implementar `pokemon_battle_state.take_damage(amount)` — Defensa absorbe primero, resto a HP, retorna daño real
- [ ] T008 Implementar `pokemon_battle_state.add_defense(amount)` — Suma Defensa (se resetea al fin de turno)
- [ ] T009 Implementar `pokemon_battle_state.apply_buff(stat, value)` / `apply_debuff(stat, value)` — Modifica stats con límites configurables
- [ ] T010 Crear `battle_state.gd` — Estado global: turno_actual, fase (player_turn/enemy_turn/victory/defeat), equipo_aliado (array[1..3] de PokemonBattleState), equipo_enemigo (array PokemonBattleState), entrenador_enemigo
- [ ] T011 Implementar ciclo de turno: `start_player_turn()` → roba mano, restaura energía, resetea Defensa → `end_player_turn()` → `execute_enemy_turn()` → `start_player_turn()`

### Phase 3: Resolución de Movimientos

**Purpose**: El motor que resuelve qué pasa cuando se juega un movimiento.

- [ ] T012 Crear `move_resolver.gd` — Método `resolve(move_data, source, target, battle_state)` que:
  - Descuenta energía del entrenador
  - Aplica daño (base_dmg × atk_buff / def_buff × type_multiplier)
  - Aplica Defensa al source si el movimiento es defensivo
  - Aplica efectos secundarios (estados, buffs, debuffs)
  - Mueve la carta de mano a descarte
- [ ] T013 Crear `status_handler.gd` — Método `process_statuses(pokemon, battle_state)` llamado al inicio de cada turno:
  - Envenenado: daño creciente (1, 2, 3... por turno)
  - Quemado: daño fijo + ataque reducido
  - Paralizado: 25% de no poder actuar (se chequea al jugar movimiento)
  - Congelado: no puede actuar, 20% de descongelar cada turno
  - Dormido: no puede actuar 1-3 turnos
  - Confundido: 50% de golpearse a sí mismo (daño reducido)
- [ ] T014 Implementar tabla de tipos elemental (type chart) para multiplicadores de daño (×2, ×0.5, ×0)

### Phase 4: Intención Enemiga e IA

**Purpose**: Sistema de intenciones visibles y patrones de IA para entrenadores enemigos.

- [ ] T015 Crear `enemy_ai.gd` — Define patrones de IA por clase de entrenador:
  - Patrón fijo: secuencia predefinida de intenciones (ej. Atacar → Defender → Atacar)
  - Patrón reactivo: elige intención según estado del combate
- [ ] T016 Implementar `Intention` como recurso con: tipo (attack/defend/buff/debuff/status), valor (daño/Defensa/buff amount), objetivo, mensaje visible
- [ ] T017 Crear `intent_display.gd` — Muestra sobre el enemigo: icono + texto (ej. ⚔️ "Placaje → 15 daño")
- [ ] T018 Implementar `enemy_ai.execute_intention(battle_state)` — Ejecuta la intención al final del turno del jugador

### Phase 5: Sistema de Furor

**Purpose**: Barra de furor (0-10) para activar mecánicas especiales.

- [ ] T019 Crear `furor_bar.gd` — Clase con: `current_furor` (int 0-10), `add_furor(amount)`, `can_afford(cost) → bool`, `spend_furor(cost)`, `reset()`
- [ ] T020 Implementar generación de furor: +1 al usar movimiento de ataque, +2 al recibir daño (por golpe), +1 al curarse, +3 al debilitar enemigo (valores configurables por acción)
- [ ] T021 Crear `mechanic_resolver.gd` — Define cada mecánica con su coste de furor y efecto:
  - Mega Evolución (coste 4): cambia sprite + stats + mazo del Pokémon por el resto del combate
  - Movimiento Z (coste 2): multiplica daño del siguiente movimiento ×2.5
  - Gigantamax/Dynamax (coste 5): +50% HP, +stats, dura 3 turnos
  - Teracrestalización (coste 3): cambia tipo elemental, bonus STAB, dura todo el combate
- [ ] T022 Implementar combinación de mecánicas: permitir activar varias en secuencia antes de resolver el movimiento
- [ ] T023 Crear `furor_bar_ui.gd` — Barra visual con segmentos que se llenan, animación de gasto

### Phase 6: UI de Combate

**Purpose**: Toda la interfaz visual del combate.

- [ ] T024 Crear `battle_scene.tscn` — Escena base con: fondo de combate, sprites de Pokémon (aliados y enemigos), HUD
- [ ] T025 Crear `battle_hud.gd` — Barra superior: HP del equipo, energía actual/máxima, furor bar, botón "Terminar Turno"
- [ ] T026 Crear `hand_display.gd` — Muestra las cartas de movimiento del Pokémon activo en abanico en la parte inferior. Soporte para hover (carta se agranda), drag (arrastrar a objetivo), click (seleccionar + confirmar)
- [ ] T027 Crear `move_card.gd` — Componente visual de una carta: nombre, coste en círculo, daño, tipo elemental (color), descripción. Estados: idle, hover, selected, unplayable (sin energía suficiente)
- [ ] T028 Crear `pokemon_info_panel.gd` — Panel del Pokémon activo: sprite, nombre, HP bar, Defensa, buffs/debuffs activos, estado alterado
- [ ] T029 Crear `target_selector.gd` — Al arrastrar/seleccionar movimiento de ataque, resalta enemigos elegibles como objetivos
- [ ] T030 Implementar animaciones: shake al recibir daño, fade al debilitarse, partículas al curar/evolucionar

### Phase 7: Mapa de la Liga

**Purpose**: Mapa procedural de nodos entre combates (estilo Slay the Spire).

- [ ] T031 Crear `map_generator.gd` — Algoritmo de generación:
  - 3 actos, cada acto con 8-15 nodos en 4-6 columnas (filas)
  - Nodos por acto: ~50% Entrenador, ~15% Élite, ~10% Evento, ~10% Tienda, ~10% Centro Pokémon, 1 Líder de Gimnasio al final
  - Garantiza al menos 2 caminos al Líder de Gimnasio
  - Conexiones solo entre nodos de columnas adyacentes
- [ ] T032 Crear `map_node.gd` — Visual de cada nodo: icono según tipo, tooltip con descripción, estado (disponible/visitado/bloqueado/inaccesible)
- [ ] T033 Crear `map_path_renderer.gd` — Líneas entre nodos conectados, antialiasing
- [ ] T034 Crear `map_camera.gd` — Scroll y pan del mapa, centrado automático en nodo actual
- [ ] T035 Integrar navegación: click en nodo disponible → transición a combate/evento/tienda/centro/Centro Pokémon

### Phase 8: Recompensas y Tienda

**Purpose**: Sistema de recompensa post-combate y tienda Pokémon.

- [ ] T036 Crear `reward_screen.gd` — Muestra 3 movimientos aleatorios del pool de la criatura activa, opción "Saltar", confirmación de selección
- [ ] T037 Crear `shop_manager.gd` — Inventario de tienda: 5 movimientos aleatorios + 3 objetos equipados a la venta, opción de eliminar movimiento por Pokédólares
- [ ] T038 Implementar economía: Pokédólares ganados por combate, costes de tienda configurables

### Phase 9: Run Summary y Persistencia

**Purpose**: Pantalla de fin de run y guardado de estado.

- [ ] T039 Crear `run_summary.gd` — Muestra: acto alcanzado, piso, puntuación, movimientos finales, objetos, botón regresar
- [ ] T040 Implementar serialización de `battle_state` a JSON para persistencia entre sesiones (no durante combate activo, solo entre nodos del mapa)
- [ ] T041 Crear sistema de carga: restaurar run desde JSON al reabrir la app

### Phase 10: Mecánicas Especiales por Historia

**Purpose**: Integración con el sistema de desbloqueo por progreso de historia.

- [ ] T042 Implementar flags de desbloqueo: `MEGA_UNLOCKED`, `Z_MOVES_UNLOCKED`, `GMAX_UNLOCKED`, `TERA_UNLOCKED`
- [ ] T043 Filtrar mecánicas disponibles en `mechanic_resolver` según flags desbloqueados
- [ ] T044 UI para mostrar mecánicas bloqueadas (gris con candado) vs disponibles

## Dependencies

- **Depende de**: `plan-creature-integration.md` (MoveData, CreatureData, pools de movimientos)
- **Bloquea**: `plan-meta-progression.md` (el modo Roguelike usa el sistema de combate)
