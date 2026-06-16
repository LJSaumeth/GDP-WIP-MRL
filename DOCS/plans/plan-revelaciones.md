# Implementation Plan: Revelaciones (Variantes de Cartas)

**Date**: 2026-06-14
**Spec**: `DOCS/specs/spec-revelaciones.md`

## Summary

Implementar el sistema de Revelaciones: variantes de cartas exclusivas y de evolución que modifican sus parámetros base. Cada carta tiene un pool de 4-8 Revelaciones. En Roguelike, al obtener una carta con Revelaciones, se ofrecen 3 al azar y el jugador elige una (o ninguna). La Revelación es permanente durante la run y altera el comportamiento de la carta en combate.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `plan-creature-integration.md` (datos de cartas exclusivas y de evolución), `plan-gameplay-deckbuilder.md` (sistema de recompensas y mazo)
**Storage**: Datos de Revelaciones definidos como recursos (`.tres`); elección del jugador en memoria durante la run
**Testing**: Test scenes in-editor
**Target Platform**: Windows D3D12
**Performance Goals**: Selección aleatoria de 3 Revelaciones <10ms, UI de selección responsive
**Constraints**: Las Revelaciones deben ser data-driven (definibles por diseñadores sin tocar código)
**Scale/Scope**: ~50 cartas exclusivas/de evolución × ~6 Revelaciones cada una = ~300 Revelaciones totales

## Project Structure

### Source Code (within `wip/`)

```text
src/combat/cards/
├── revelation_data.gd           # Recurso: datos de una Revelación individual
├── revelation_pool.gd           # Recurso: pool de Revelaciones por carta
├── revelation_card.gd           # Wrapper: carta base + Revelación aplicada
└── revelation_resolver.gd       # Aplica modificadores de Revelación al resolver la carta

src/combat/ui/
└── revelation_select_ui.gd      # Pantalla de selección: 3 Revelaciones + "Sin Revelación"
```

### Data Resources (within `wip/resources/revelations/`)

```text
resources/revelations/
├── pikachu/
│   ├── rayo_fulminante_pool.tres
│   ├── rev_carga_paralizante.tres
│   ├── rev_rayo_en_cadena.tres
│   ├── rev_sobrevoltaje.tres
│   └── rev_descarga_estatica.tres
├── charizard/
│   └── ...
└── ...
```

## Clean Code Guidelines

### Naming & Style
- **Clases**: `PascalCase` — `RevelationData`, `RevelationPool`, `RevelationCard`, `RevelationResolver`
- **Variables/métodos**: `snake_case` — `damage_mod`, `cost_mod`, `generate_offering()`, `apply_modifiers()`
- **Constantes**: `UPPER_SNAKE_CASE` — `MIN_POOL_SIZE = 4`, `MAX_POOL_SIZE = 8`, `OFFERING_SIZE = 3`
- **Señales**: `snake_case` en pasado — `revelation_selected`, `offering_generated`

### Single Responsibility
- **RevelationData** (`revelation_data.gd`): Resource puro con campos de modificación; sin lógica
- **RevelationPool** (`revelation_pool.gd`): Resource — solo datos del pool + `generate_offering()`
- **RevelationCard** (`revelation_card.gd`): Wrapper inmutable base_card + revelation; calcula stats finales
- **RevelationResolver** (`revelation_resolver.gd`): Solo lógica de aplicación de modificadores en combate
- **UI** (`revelation_select_ui.gd`): Solo presentación de la selección; emite señal con la elección

### Métodos
- `generate_offering()` debe ser Fisher-Yates puro; no mezclar con lógica de UI
- **Guard clauses**: `if not pool or pool.is_empty(): return []` al inicio de `generate_offering()`
- `apply_revelation_modifiers()` recibe dict inmutable, retorna dict modificado — sin side effects
- `get_final_card_data()` calcula todos los stats finales en un solo método cacheable

### Godot-Specific
- `RevelationData` y `RevelationPool` como Resources (`.tres`), editables en el inspector de Godot
- `RevelationCard` como Resource creado en runtime al seleccionar Revelación
- `RevelationResolver` como método estático o singleton — no necesita estado
- `@export var pool: RevelationPool` en la escena de recompensa para testing rápido
- Señal `SignalBus.revelation_selected.emit(revelation_card)` para que el sistema de mazo añada la carta

### Valores configurables
- Tamaño de pool (4-8) y tamaño de offering (3) en constantes, no hardcodeados
- Modificadores de cada Revelación en `.tres` individuales — el diseñador los crea sin tocar código
- `furor_gen_mod` como campo opcional en `RevelationData` (0 = sin modificación)

---

## Phases

### Phase 1: Estructuras de Datos

**Purpose**: Definir los recursos y clases base para Revelaciones y sus pools.

- [ ] T001 Crear `revelation_data.gd` (Resource) con propiedades:
  - `id: String` — Identificador único (ej: "rev_pikachu_rayo_paralizante")
  - `name: String` — Nombre visible (ej: "Carga Paralizante")
  - `description: String` — Descripción del efecto (ej: "+50% probabilidad de Paralizar, -5 daño")
  - `damage_mod: int` — Modificador de daño (+/-)
  - `cost_mod: int` — Modificador de coste de energía (+/-)
  - `elemental_type_override: String` — Tipo elemental alternativo (vacío = sin cambio)
  - `secondary_effects_mod: Array[Dictionary]` — Efectos secundarios a añadir/modificar
  - `target_type_override: String` — Cambio de single-target a multi-target (vacío = sin cambio)
  - `furor_gen_mod: int` — Modificador de generación de furor al usar la carta (+/-)

- [ ] T002 Crear `revelation_pool.gd` (Resource) con propiedades:
  - `card_id: String` — ID de la carta a la que pertenece este pool
  - `revelations: Array[RevelationData]` — Lista de Revelaciones (4-8 elementos)
  - Método `generate_offering() → Array[RevelationData]` — Selecciona 3 Revelaciones al azar sin repetición

- [ ] T003 Implementar `generate_offering()` en `revelation_pool.gd`:
  - Toma el array `revelations`, lo baraja (Fisher-Yates)
  - Toma los primeros `min(3, len(revelations))` elementos
  - Si el pool tiene menos de 3, rellena con nulls (slots vacíos)
  - Si el pool está vacío (caso de carta sin Revelaciones), retorna array vacío

- [ ] T004 Crear `revelation_card.gd` (Resource) — Wrapper que vincula una carta base con una Revelación:
  - `base_card_id: String`
  - `revelation_id: String` (vacío si es "Sin Revelación")
  - `final_damage: int` — `base_card.damage + revelation.damage_mod`
  - `final_cost: int` — `max(0, base_card.cost + revelation.cost_mod)`
  - `final_elemental_type: String` — `revelation.elemental_type_override or base_card.elemental_type`
  - Método `get_final_card_data() → Dictionary` — Retorna todos los datos resueltos de la carta

---

### Phase 2: Selector de Revelación (UI)

**Purpose**: Pantalla de selección de Revelación que se integra en el flujo de recompensa.

- [ ] T005 Crear `revelation_select_ui.gd` — Escena con:
  - Título: "Elige una Revelación para [nombre de la carta]"
  - 3 slots para Revelaciones, cada uno mostrando:
    - Nombre de la Revelación
    - Descripción del efecto
    - Preview de la carta modificada (stats comparados: tachado original → nuevo)
  - Botón "Sin Revelación" (mantener versión base)
  - Confirmación: al elegir, se crea el `RevelationCard` y se emite señal `revelation_selected(revelation_card)`

- [ ] T006 Implementar preview de stats en la UI:
  - Daño base tachado → daño modificado con color (verde si mejora, rojo si empeora, blanco si sin cambio)
  - Coste base tachado → coste modificado con color
  - Tipo elemental: mostrar cambio si aplica (ej: "Fuego → Fuego + Agua")
  - Efectos secundarios: mostrar los nuevos/añadidos resaltados

- [ ] T007 Integrar con el flujo de recompensa existente (`reward_screen.gd`):
  - Hook en el momento de añadir carta al mazo
  - Si la carta tiene `revelation_pool` no vacío → intercalar `revelation_select_ui` entre la selección de carta y la confirmación
  - Si la carta no tiene pool → flujo normal (añadir directamente)

- [ ] T008 Probar en escena de test: forzar recompensa de carta exclusiva, verificar que aparece la selección de Revelación, elegir una, confirmar que la carta se añade con los stats modificados

---

### Phase 3: Resolución en Combate

**Purpose**: Las Revelaciones aplican sus modificadores cuando la carta se juega en combate.

- [ ] T009 Crear `revelation_resolver.gd` — Método estático `apply_revelation_modifiers(base_resolution_data, revelation_data) → modified_resolution_data`:
  - Toma los datos de resolución base del movimiento
  - Aplica `damage_mod` al daño calculado
  - Aplica cambios de tipo elemental para el cálculo de multiplicadores
  - Añade/modifica efectos secundarios según `secondary_effects_mod`
  - Aplica `furor_gen_mod` si corresponde
  - Retorna los datos modificados listos para ser ejecutados por `move_resolver.gd`

- [ ] T010 Integrar `revelation_resolver` en el pipeline de `move_resolver.gd`:
  - Al resolver un movimiento, verificar si la carta tiene `revelation_id`
  - Si tiene → pasar por `revelation_resolver` antes de la resolución normal
  - Si no tiene → flujo normal sin cambios

- [ ] T011 Implementar indicador visual de Revelación en la carta en mano (`move_card.gd`):
  - Borde especial (ej: borde dorado o con patrón)
  - Ícono pequeño con la inicial de la Revelación o un símbolo
  - Stats ya modificados visibles directamente en la carta (no solo en tooltip)
  - Tooltip extendido: nombre de la Revelación + descripción de su efecto

- [ ] T012 Probar en combate: jugar una carta con Revelación, verificar que el daño, coste, tipo y efectos corresponden a la Revelación elegida

---

### Phase 4: Creación de Pools (Contenido)

**Purpose**: Definir los pools de Revelaciones para todas las cartas exclusivas y de evolución.

- [ ] T013 Crear recurso `.tres` para cada Revelación (aprox. 300 archivos). Usar script de generación batch o crear manualmente las primeras 20-30 como muestra.
- [ ] T014 Crear recurso `revelation_pool.tres` para cada carta exclusiva y de evolución, asignando sus Revelaciones.
- [ ] T015 Validar que cada pool tiene entre 4 y 8 Revelaciones, y que ninguna carta común tiene pool asignado (test automático).
- [ ] T016 Documentar guía de diseño para Revelaciones: balance de trade-offs, diversidad de efectos dentro de un mismo pool, evitar "best option" obvia.

---

### Phase 5: Pulido y Edge Cases

**Purpose**: Manejar casos borde y pulir la experiencia de usuario.

- [ ] T017 Manejar pool con <3 Revelaciones: mostrar las disponibles, slots vacíos con mensaje "No hay más Revelaciones disponibles"
- [ ] T018 Manejar coste <0: `final_cost = max(0, base_cost + cost_mod)` — forzar mínimo 0
- [ ] T019 Interacción Revelación + Teracrestalización: si ambos cambian el tipo, el tipo Tera tiene prioridad (es decir, el tipo de la Revelación se ignora para el cálculo de STAB si el Pokémon está Teracrestalizado)
- [ ] T020 Interacción Revelación + Furor: si `furor_gen_mod != 0`, el `furor_bar.gd` recibe el modificador al resolver la carta
- [ ] T021 Animación de selección de Revelación: transición suave al elegir, efecto de "brillo" en la carta al añadirse al mazo
- [ ] T022 Sonido: SFX al abrir la pantalla de Revelaciones, SFX al seleccionar una, SFX distinto para "Sin Revelación"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies — fundacional, bloquea todo
- **Phase 2**: Depende de Phase 1 (necesita `revelation_pool` y `revelation_card`)
- **Phase 3**: Depende de Phase 1 (necesita `revelation_card` y `revelation_resolver`)
- **Phase 4**: Depende de Phase 1 (necesita estructuras de datos definidas). Puede hacerse en paralelo con Phase 2 y 3.
- **Phase 5**: Depende de Phase 2 y 3 (necesita sistema funcional para pulir)

### Dependencias Externas

- **Depende de**: `plan-gameplay-deckbuilder.md` (sistema de recompensas, `move_resolver.gd`, `move_card.gd`)
- **Depende de**: `plan-creature-integration.md` (datos de cartas exclusivas y de evolución)
- **Referenciado por**: `plan-gameplay-deckbuilder.md` (la pantalla de recompensa integra la selección de Revelación)
