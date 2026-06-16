# Implementation Plan: Inventario y Objetos Equipados

**Date**: 2026-06-16
**Spec**: `DOCS/specs/spec-inventory-items.md`

## Summary

Implementar el sistema de inventario con dos contextos (historia y run), Held Items equipables (1 por Pokémon) con hooks de activación en combate, objetos consumibles, materiales de evolución permanentes, y objetos clave. Moneda (Pokédólares) ganada en combate y gastada en tiendas. Integración con todos los sistemas existentes (combate, criaturas, overworld, dating, meta-progresión).

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `plan-creature-integration.md` (CharacterData), `plan-gameplay-deckbuilder.md` (combat hooks)
**Storage**: Inventory serialized in save file; run inventory persisted between map nodes
**Testing**: Test scenes in-editor
**Target Platform**: Windows D3D12
**Performance Goals**: Inventory UI load <100ms, item effect resolution <10ms
**Constraints**: Held Item hooks must not block combat resolution pipeline
**Scale/Scope**: ~30 Held Items, ~10 consumables, ~10 materials, ~10 key items

## Project Structure

### Source Code (within `wip/`)

```text
src/inventory/
├── resources/
│   ├── item_data.gd              # Resource script: ItemData (base)
│   ├── held_item_data.gd         # Resource script: HeldItemData extends ItemData
│   ├── consumable_data.gd        # Resource script: ConsumableData extends ItemData
│   ├── material_data.gd          # Resource script: MaterialData extends ItemData
│   ├── key_item_data.gd          # Resource script: KeyItemData extends ItemData
│   ├── held_items/               # .tres files per held item (restos.tres, hierro.tres, ...)
│   ├── consumables/              # .tres files per consumable (pocion.tres, repelente.tres, ...)
│   ├── materials/                # .tres files per material
│   └── key_items/                # .tres files per key item
├── state/
│   ├── inventory.gd              # Inventory state: all item storage, pokédollars
│   ├── run_inventory.gd          # Run-scoped inventory (held items + pokédollars), resets per run
│   └── equipped_item_slot.gd     # Runtime: which held item is on which pokemon (0-2)
├── hooks/
│   ├── held_item_hooks.gd        # Dispatches held item effects at combat event hooks
│   └── item_effect_resolver.gd   # Resolves item effects (heal, buff, damage, etc.)
├── managers/
│   ├── inventory_manager.gd      # Autoload: CRUD for both story and run inventories
│   └── item_database.gd          # Autoload: loads all .tres item resources
├── shop/
│   └── shop_inventory.gd         # Shop inventory generation (5 moves + 3 held items)
└── ui/
    ├── inventory_menu.gd         # Full inventory screen with tabs
    ├── inventory_tab.gd          # Individual tab (Held Items / Consumables / Materials / Key)
    ├── item_slot_ui.gd           # Single item display (icon, name, description on hover)
    ├── equip_screen.gd           # Assign held items to team pokemon
    └── currency_display.gd       # Pokédollars counter in HUD
```

## Clean Code Guidelines

### Naming & Style
- **Clases**: `PascalCase` — `Inventory`, `HeldItemData`, `ItemDatabase`, `HeldItemHooks`
- **Variables/métodos**: `snake_case` — `pokédollars`, `held_items`, `equip_item()`, `use_consumable()`
- **Constantes**: `UPPER_SNAKE_CASE` — `MAX_HELD_ITEMS_PER_POKEMON = 1`, `CURRENCY_SYMBOL = "¥"`
- **Señales**: `snake_case` en pasado — `item_equipped`, `item_consumed`, `pokédollars_changed`
- **Enums**: `PascalCase` para tipo — `ItemCategory.HELD`, `ActivationHook.ON_TURN_START`

### Single Responsibility
- **Resources** (`resources/`): Data definition only; no runtime logic
- **State** (`state/`): Mutable runtime storage; getters/setters and validation
- **Hooks** (`hooks/`): Dispatch effects at combat events; delegate to resolver
- **Managers** (`managers/`): Loading, querying, and cross-system coordination
- **UI** (`ui/`): Pure presentation; observes state via signals

### Métodos
- `use_consumable()` with guard: `if hp_full: return ERR_ALREADY_FULL`
- `equip_held_item()` validates: `if pokemon_already_has_item: unequip_first()`
- Item hook dispatch via dictionary lookup, not if-else chains: `HOOKS[hook_name].call(item, pokemon, context)`
- Pokemon KO handler: `on_pokemon_defeated()` auto-unequips and returns item to run inventory

### Godot-Specific
- `inventory_manager` as Autoload for global access
- `item_database` as Autoload, loads all items at boot into O(1) dictionary
- `@export var activation_hooks: Array[String]` on HeldItemData for designer configuration
- Signals: `SignalBus.item_equipped.emit(pokemon_index, item_id)` for UI updates
- `ResourceLoader.load()` for item `.tres` files; no hardcoded paths

### Valores configurables
- Item prices, effect values, and hook types in `.tres` Resources
- Pokédollar rewards per trainer class in `@export var trainer_rewards: Dictionary`
- Shop inventory size and prices in `@export var shop_config: Dictionary`

## Phases

### Phase 1: Data Resources (Fundacional)

**Purpose**: Define the Resource types and create initial item catalog.

- [ ] T001 Crear `item_data.gd` — Resource base con: `id: String`, `display_name: String`, `description: String`, `sprite_path: String`, `category: ItemCategory` (enum HELD/CONSUMABLE/MATERIAL/KEY)
- [ ] T002 Crear `held_item_data.gd` — Extiende ItemData. Campos: `activation_hooks: Array[String]`, `effect_params: Dictionary`, `consumes_on_use: bool`
- [ ] T003 Crear `consumable_data.gd` — Extiende ItemData. Campos: `target_type: String` (SINGLE_ALLY, WHOLE_TEAM, OVERWORLD), `effect_params: Dictionary`
- [ ] T004 Crear `material_data.gd` — Extiende ItemData. Campos: `evolution_ids: Array[String]`
- [ ] T005 Crear `key_item_data.gd` — Extiende ItemData. Campos: `unlock_flag: String`, `auto_use: bool`
- [ ] T006 Crear `.tres` files para al menos 10 Held Items iniciales con sus hooks y efectos
- [ ] T007 Crear `.tres` files para al menos 4 consumibles (Poción, Súper Poción, Repulsor, Cura Total)
- [ ] T008 Crear `.tres` files para materiales de evolución (mismos definidos en creature integration)
- [ ] T009 Crear `.tres` files para al menos 3 objetos clave iniciales

### Phase 2: Inventory State & Manager

**Purpose**: Core inventory data structures and the manager autoload.

- [ ] T010 Crear `inventory.gd` — Clase de estado con: `pokédollars: int`, `held_items: Array[HeldItemData]`, `consumables: Dictionary[String → int]`, `materials: Array[MaterialData]`, `key_items: Array[KeyItemData]`. Métodos: `add_item(item)`, `remove_item(item_id, amount)`, `has_item(item_id) → bool`, `get_count(item_id) → int`
- [ ] T011 Crear `run_inventory.gd` — Wrapper de Inventory para contexto de run: solo Held Items y Pokédollars. Método `reset()` que vacía ambos al iniciar nueva run
- [ ] T012 Crear `equipped_item_slot.gd` — Array fijo de 3 slots (null = sin objeto). Métodos: `equip(pokemon_index, item)`, `unequip(pokemon_index) → HeldItemData`, `get_equipped(pokemon_index) → HeldItemData`
- [ ] T013 Crear `inventory_manager.gd` — Autoload. Contiene: `story_inventory: Inventory` (persistente), `run_inventory: RunInventory` (efímero), `equipped_slots: EquippedItemSlot`. Métodos: `get_pokédollars()`, `add_pokédollars(amount)`, `spend_pokédollars(amount) → bool`
- [ ] T014 Crear `item_database.gd` — Autoload. Carga todos los `.tres` de las 4 carpetas de items. Método: `get_item(id) → ItemData`, `get_held_items() → Array[HeldItemData]`, `get_consumables() → Array[ConsumableData]`

### Phase 3: Held Item Hooks in Combat

**Purpose**: Integrate held items into the combat pipeline via hooks.

- [ ] T015 Crear `held_item_hooks.gd` — Método `dispatch(hook_name: String, battle_state)` que itera los 3 slots equipados, verifica si el Held Item tiene ese hook, y ejecuta el efecto
- [ ] T016 Crear `item_effect_resolver.gd` — Resuelve efectos de items: `apply_heal(target, amount)`, `apply_buff(target, stat, value)`, `prevent_death(target) → bool`, `modify_damage(original_damage, modifier) → int`
- [ ] T017 Integrar hooks en el pipeline de combate (`battle_state.gd`):
  - `on_combat_start` → llamado al iniciar `battle_state.start_battle()`
  - `on_turn_start` → llamado al inicio de `start_player_turn()`
  - `on_turn_end` → llamado al inicio de `end_player_turn()`
  - `on_damage_taken` → hook en `pokemon_battle_state.take_damage()` antes de aplicar daño
  - `on_enemy_defeated` → hook al debilitar un Pokémon enemigo
  - `on_death_prevented` → hook al detectar daño letal (antes de aplicar HP=0)
- [ ] T018 Auto-unequip on KO: cuando un Pokémon aliado es debilitado, su Held Item vuelve al `run_inventory`

### Phase 4: Consumables & Key Items

**Purpose**: Consumable usage and key item auto-triggers.

- [ ] T019 Implementar uso de consumibles desde menú de inventario (fuera de combate):
  - Pociones: curan HP al Pokémon seleccionado
  - Repulsor: activa `repell_manager` por X pasos
  - Cura de estado: elimina estado alterado del Pokémon seleccionado
- [ ] T020 Implementar auto-uso de objetos clave: al llegar a un trigger de zona/evento, `inventory_manager.has_key_item(required_flag)` desbloquea el acceso
- [ ] T021 Validar que no se puede usar consumible si el efecto no aplica (HP lleno, sin estado alterado, etc.)

### Phase 5: Shop Integration

**Purpose**: Connect inventory to the shop system.

- [ ] T022 Actualizar `shop_manager.gd` para usar `item_database` y `inventory_manager`:
  - Generar 5 movimientos aleatorios + 3 Held Items aleatorios del catálogo
  - Precios desde Resources; compra descuenta `pokédollars`
  - Opción de vender/eliminar movimiento (misma lógica que ya existe)
- [ ] T023 Implementar `shop_inventory.gd` — Lógica de generación de inventario de tienda: `generate_shop_items(act_number, player_level) → ShopOffer`

### Phase 6: Persistence

**Purpose**: Save and load inventory across sessions.

- [ ] T024 Serializar `story_inventory` (materiales, objetos clave, consumibles) en save file usando `inst_to_dict`
- [ ] T025 Serializar `run_inventory` (Held Items, Pokédollars) entre nodos del mapa roguelike
- [ ] T026 Al iniciar nueva run: `run_inventory.reset()` — vacía Held Items, Pokédollars a 0
- [ ] T027 En NG+: resetear `story_inventory` (materiales, key items, consumables) a estado inicial

### Phase 7: UI

**Purpose**: Inventory screens and HUD elements.

- [ ] T028 Crear `inventory_menu.gd` + `.tscn` — Pantalla completa con tabs: Held Items, Consumibles, Materiales, Objetos Clave
- [ ] T029 Crear `item_slot_ui.gd` — Componente reutilizable: sprite, nombre, cantidad (si aplica), tooltip con descripción al hover
- [ ] T030 Crear `equip_screen.gd` — Grid de 3 Pokémon del equipo, cada uno con slot para Held Item; drag & drop o click para equipar/desequipar
- [ ] T031 Crear `currency_display.gd` — Contador de Pokédólares en HUD de overworld y HUD de combate

### Phase 8: Integration Tests

- [ ] T032 Test de integración: equipar Held Item → iniciar combate → verificar que el efecto se dispara en el hook correcto
- [ ] T033 Test de integración: ganar Pokédólares en combate → verificar que se reflejan en inventario → gastar en tienda → verificar descuento
- [ ] T034 Test de ciclo de run: iniciar run → obtener Held Items → morir/completar → iniciar nueva run → verificar inventario vacío

## Dependencies

- **Depende de**: `plan-creature-integration.md` (CharacterData, materiales), `plan-gameplay-deckbuilder.md` (combat hooks, battle_state, shop)
- **Bloquea**: Ninguno directamente (los sistemas pueden funcionar sin items inicialmente)
- **Relacionado con**: `plan-overworld-exploration.md` (repelentes, items en cofres), `plan-dating-sim.md` (date rewards), `plan-meta-progression.md` (run inventory reset, shop)
