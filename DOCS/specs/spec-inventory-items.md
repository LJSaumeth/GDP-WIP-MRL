# Feature Specification: Inventario y Objetos Equipados

**Created**: 2026-06-16

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inventario Básico y Moneda (Priority: P1)

El jugador tiene un inventario accesible desde cualquier momento del juego (pausa, overworld, entre combates). El inventario muestra: Pokédólares (moneda), objetos equipados (Held Items), objetos consumibles, materiales de evolución, y objetos clave. Los Pokédólares se ganan al vencer combates y se gastan en tiendas.

**Why this priority**: Sin inventario no hay economía ni objetos equipados. Es un prerequisito para todos los demás sistemas de items.

**Independent Test**: Se puede testear creando un inventario con valores hardcodeados y verificando que la UI muestra correctamente todos los tipos de items y sus cantidades.

**Acceptance Scenarios**:

1. **Scenario**: Ver inventario desde overworld
   - **Given** el jugador está en el overworld
   - **When** abre el menú de pausa y selecciona "Inventario"
   - **Then** se muestra la lista completa de items con nombre, sprite, cantidad (si aplica) y categoría

2. **Scenario**: Ganar Pokédólares tras combate
   - **Given** el jugador vence un combate contra un Entrenador
   - **When** se muestra la pantalla de recompensa
   - **Then** los Pokédólares ganados se suman al total del inventario de la run

3. **Scenario**: Pokédólares insuficientes en tienda
   - **Given** el jugador tiene 50 Pokédólares y un objeto cuesta 100
   - **When** intenta comprar el objeto
   - **Then** la compra se rechaza y se muestra feedback de "Pokédólares insuficientes"

---

### User Story 2 - Objetos Equipados (Held Items) (Priority: P2)

El jugador puede equipar un objeto (Held Item) a cada Pokémon del equipo (máximo 1 por Pokémon). Los objetos equipados otorgan efectos pasivos durante el combate según hooks predefinidos (inicio de combate, inicio de turno, al recibir daño, al debilitar enemigo). Los objetos se obtienen durante runs roguelike y no persisten entre runs.

**Why this priority**: Los Held Items son la capa de build que diferencia runs. Importantes para profundidad pero el juego es jugable sin ellos.

**Independent Test**: Se puede testear asignando un Held Item a un Pokémon al inicio de run y verificando que su efecto se dispara en el hook correcto durante combate.

**Acceptance Scenarios**:

1. **Scenario**: Equipar objeto a un Pokémon
   - **Given** el jugador tiene "Restos" en el inventario de la run y el Pokémon activo no tiene objeto equipado
   - **When** asigna "Restos" al Pokémon desde la pantalla de equipo
   - **Then** "Restos" se marca como equipado y el Pokémon muestra el icono del objeto en la UI de combate

2. **Scenario**: Efecto de objeto al inicio de combate
   - **Given** un Pokémon tiene "Hierro" equipado (+Defensa al inicio del combate)
   - **When** comienza un nuevo combate
   - **Then** el Pokémon inicia con +5 Defensa aplicada antes del primer turno

3. **Scenario**: Efecto de objeto al final del turno
   - **Given** un Pokémon tiene "Restos" equipado (recupera 2 HP al final del turno)
   - **When** termina el turno del jugador
   - **Then** el Pokémon recupera 2 HP (sin exceder HP máximo)

4. **Scenario**: Efecto de objeto al recibir daño
   - **Given** un Pokémon tiene "Cinta Focus" equipado (sobrevive con 1 HP si recibiría daño letal desde HP > 1)
   - **When** recibe daño que reduciría su HP a 0 o menos
   - **Then** el Pokémon sobrevive con 1 HP y el objeto se consume/destruye

5. **Scenario**: Solo 1 objeto por Pokémon
   - **Given** el Pokémon activo ya tiene "Restos" equipado
   - **When** el jugador intenta equipar "Hierro" al mismo Pokémon
   - **Then** "Restos" se desequipa automáticamente y "Hierro" toma su lugar

6. **Scenario**: Objetos no persisten entre runs
   - **Given** el jugador tiene 3 Held Items al finalizar una run roguelike (muerte o victoria)
   - **When** inicia una nueva run
   - **Then** el inventario de la run comienza vacío (sin Held Items); los objetos de la run anterior no se conservan

---

### User Story 3 - Objetos Consumibles (Priority: P3)

El jugador puede obtener objetos consumibles que se usan una vez y desaparecen: pociones (curan HP), objetos de estado (curan estado alterado), Repulsor (evita encuentros aleatorios temporalmente). Los consumibles se pueden usar fuera de combate.

**Why this priority**: Añaden opciones tácticas entre combates pero no son esenciales para el loop principal.

**Independent Test**: Se puede testear creando una poción en el inventario, usándola fuera de combate y verificando que cura HP y desaparece.

**Acceptance Scenarios**:

1. **Scenario**: Usar poción entre combates
   - **Given** un Pokémon del equipo tiene 20/50 HP y el inventario tiene "Poción" (cura 20 HP)
   - **When** el jugador usa la poción desde el menú de inventario
   - **Then** el Pokémon recupera 20 HP, la poción se consume y desaparece del inventario

2. **Scenario**: Usar Repulsor en overworld
   - **Given** el jugador está en una zona hostil y tiene "Repulsor" en el inventario
   - **When** usa el Repulsor
   - **Then** los encuentros aleatorios se desactivan por 100 pasos; el contador aparece en el HUD

3. **Scenario**: Consumible sin efecto si HP está lleno
   - **Given** todo el equipo tiene HP al máximo
   - **When** el jugador intenta usar una poción
   - **Then** el uso se bloquea y se muestra "No es necesario"

---

### User Story 4 - Materiales de Evolución y Objetos Clave (Priority: P3)

Los materiales de evolución (Piedra Trueno, Piedra Fuego, etc.) son objetos especiales que no se consumen al usarse y persisten permanentemente en la partida. Se obtienen en puntos específicos de la historia. Los objetos clave (Key Items) desbloquean progresión (llaves, herramientas, vehículos).

**Why this priority**: Son necesarios para la progresión de criaturas e historia, pero se pueden implementar con flags en lugar de items reales durante desarrollo temprano.

**Independent Test**: Se puede testear otorgando una Piedra Trueno vía evento y verificando que aparece en el inventario y habilita la evolución de Pikachu.

**Acceptance Scenarios**:

1. **Scenario**: Material de evolución no se consume
   - **Given** el jugador tiene "Piedra Fuego" y Charmander evoluciona a Charmeleon usándola
   - **When** la evolución se completa
   - **Then** "Piedra Fuego" permanece en el inventario y puede usarse para otras evoluciones

2. **Scenario**: Material se obtiene por evento de historia
   - **Given** el jugador completa el evento "Cueva Granito"
   - **When** se resuelve el evento
   - **Then** "Piedra Trueno" se añade al inventario permanentemente

3. **Scenario**: Objeto clave desbloquea zona
   - **Given** la "Llave del Gimnasio" está en el inventario
   - **When** el jugador llega a la puerta del Gimnasio
   - **Then** la puerta se abre automáticamente al detectar la llave

---

### Edge Cases

- **Inventario lleno**: El inventario no tiene límite de capacidad. No se rechazan items por espacio.
- **Objeto equipado al morir Pokémon**: El Held Item se desequipa y vuelve al inventario de la run al debilitarse el Pokémon en combate.
- **Objeto equipado y movimiento con efectos contradictorios**: Se activa primero el objeto equipado, luego el movimiento (consistente con spec-gameplay-deckbuilder).
- **Dos objetos con mismo hook**: El orden de activación es por índice de Pokémon en el equipo (0, 1, 2).
- **Pokédólares entre runs**: Los Pokédólares se resetean a 0 al iniciar cada nueva run roguelike.
- **Materiales en NG+**: Los materiales de evolución se pierden al iniciar NG+ (se reinicia el inventario de historia).
- **Objeto clave duplicado**: Los objetos clave son únicos; si se intenta añadir uno que ya existe, se ignora.
- **Venta de Held Items**: Los Held Items sobrantes al final de una run NO se pueden vender por Legacy Points. Solo se pierden.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mantener un inventario accesible desde cualquier punto del juego (overworld, entre combates, pausa).
- **FR-002**: El sistema DEBE distinguir entre dos contextos de inventario: inventario de historia (persistente, contiene materiales, objetos clave) e inventario de run (efímero, contiene Pokédólares y Held Items).
- **FR-003**: El sistema DEBE soportar una moneda (Pokédólares) que se gana al vencer combates y se gasta en tiendas. Se resetea a 0 al iniciar cada run roguelike.
- **FR-004**: El sistema DEBE permitir equipar exactamente 1 Held Item por Pokémon del equipo.
- **FR-005**: Cada Held Item DEBE definir al menos un hook de activación y su efecto asociado. Los hooks disponibles son: `on_combat_start`, `on_turn_start`, `on_turn_end`, `on_damage_taken`, `on_damage_dealt`, `on_enemy_defeated`, `on_heal`, `on_move_played`, `on_death_prevented`.
- **FR-006**: El sistema DEBE resolver los efectos de Held Items en el pipeline de combate, después de la resolución del movimiento pero antes de la finalización del evento.
- **FR-007**: Los Held Items DEBEN ser específicos de cada run roguelike. Al iniciar una nueva run, el inventario de Held Items comienza vacío.
- **FR-008**: El sistema DEBE soportar objetos consumibles que se usan una vez y desaparecen (pociones, Repulsor, cura de estado).
- **FR-009**: Los materiales de evolución DEBEN persistir permanentemente en la partida de historia. No se consumen al usarse en una evolución.
- **FR-010**: Los objetos clave (Key Items) DEBEN desbloquear mecánicas de progresión: acceso a zonas, vehículos, eventos de historia.
- **FR-011**: El sistema DEBE proveer una UI de inventario con categorías (tabs o secciones): Held Items, Consumibles, Materiales, Objetos Clave.
- **FR-012**: El sistema DEBE persistir el inventario de historia (materiales, objetos clave) en el save file de la partida.
- **FR-013**: El sistema DEBE persistir el inventario de run (Pokédólares, Held Items) entre nodos del mapa roguelike, no durante combate activo.
- **FR-014**: El sistema DEBE permitir reasignar Held Items entre Pokémon del equipo SOLO fuera de combate (entre nodos del mapa).

### Key Entities

- **Item (Item Base)**: Objeto del juego. Atributos: `id`, `name`, `description`, `sprite_path`, `category` (enum: HELD / CONSUMABLE / MATERIAL / KEY).
- **HeldItem (Objeto Equipado)**: Item categoría HELD. Atributos adicionales: `activation_hooks` (array de strings con nombres de hooks), `effects` (dict con parámetros del efecto: p.ej. `{"heal_amount": 2, "hook": "on_turn_end"}`), `consumable_on_use` (bool, si se destruye tras activarse — ej. Focus Sash).
- **ConsumableItem (Consumible)**: Item categoría CONSUMABLE. Atributos adicionales: `target` (SINGLE_ALLY / WHOLE_TEAM / OVERWORLD), `effect` (dict: `{"heal_hp": 20}` o `{"cure_status": true}` o `{"repel_steps": 100}`).
- **MaterialItem (Material)**: Item categoría MATERIAL. Atributos adicionales: `evolution_id` (a qué evoluciones aplica). No se consume al usarse.
- **KeyItem (Objeto Clave)**: Item categoría KEY. Atributos adicionales: `unlock_flag` (string, flag de historia que activa), `auto_use` (bool, si se activa automáticamente al detectar trigger).
- **Inventory (Inventario)**: Estado del inventario. Atributos: `pokédollars` (int), `held_items` (array de HeldItem, objetos de la run), `consumables` (dict[item_id → cantidad]), `materials` (array de MaterialItem), `key_items` (array de KeyItem). Métodos: `add_item(item)`, `remove_item(item_id)`, `has_item(item_id) → bool`, `equip_held_item(pokemon_index, held_item)`, `unequip_held_item(pokemon_index)`.
- **EquippedItem (Objeto en Pokémon)**: Vinculo runtime entre un Pokémon del equipo y un Held Item. Atributos: `pokemon_index`, `held_item`. El equipo tiene un array de 3 EquippedItem (puede ser null si no hay objeto).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: La UI de inventario abre y carga todos los items en menos de 100ms con hasta 50 items acumulados.
- **SC-002**: El 100% de los Held Items activan su efecto en el hook correcto durante combate, verificado con prueba automatizada para cada tipo de hook.
- **SC-003**: Los Pokédólares se calculan correctamente (ganancia + gasto) y nunca entran en valores negativos.
- **SC-004**: Los materiales de evolución no se consumen al usarse en el 100% de las evoluciones realizadas.
- **SC-005**: El inventario de run se resetea correctamente al iniciar una nueva run roguelike (Held Items y Pokédólares a 0/vacío).
- **SC-006**: El inventario de historia se guarda y restaura correctamente tras cerrar y reabrir la aplicación en el 100% de los casos.
