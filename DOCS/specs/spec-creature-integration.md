# Feature Specification: Integración de Criaturas

**Created**: 2026-06-12

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Asignación de Criatura a Personaje (Priority: P1)

Cada personaje jugable (incluido el protagonista) tiene UNA (1) criatura asignada de forma fija. En código, "Protagonista & Pikachu" y "Protagonista & Charmander" son entidades de personaje diferentes (comparten nombre y sprite base, pero tienen distinta criatura, mazo de cartas y stats). Esto aplica a todos los personajes del equipo.

**Why this priority**: La criatura define las cartas del personaje. Sin esta asignación no existe el sistema de combate.

**Independent Test**: Se puede testear creando dos versiones del mismo personaje con diferentes criaturas (mismo sprite, diferente mazo) y verificando que en combate usan las cartas correctas.

**Acceptance Scenarios**:

1. **Scenario**: Personaje usa cartas de su criatura
   - **Given** el personaje "Prota & Pikachu" está en combate
   - **When** se roba la mano inicial
   - **Then** todas las cartas en el mazo pertenecen al pool de cartas definido por la criatura "Pikachu"

2. **Scenario**: Dos versiones del mismo personaje con diferente criatura
   - **Given** existen "Prota & Pikachu" y "Prota & Charmander" como entidades separadas
   - **When** se compara el mazo de cada uno
   - **Then** los mazos son completamente diferentes (cartas de tipo eléctrico vs tipo fuego)

3. **Scenario**: Personaje sin criatura no es jugable en combate
   - **Given** se intenta asignar a un personaje sin criatura definida al equipo
   - **When** se confirma la selección de equipo
   - **Then** el sistema rechaza el equipo y notifica que el personaje necesita una criatura

---

### User Story 2 - Pool de Cartas Definido por Criatura (Priority: P1)

Cada criatura define un pool de cartas disponible para el personaje. El pool incluye cartas comunes a todas las criaturas (básicas) y cartas exclusivas de esa criatura o tipo elemental. En modo Historia, el mazo inicial es fijo. En modo Roguelike, se construye a partir del pool durante la run.

**Why this priority**: Es el núcleo de la diferenciación entre personajes. Sin pools distintos, todos los personajes jugarían igual.

**Independent Test**: Se puede testear creando 2 criaturas con pools distintos y verificando que las cartas ofrecidas como recompensa pertenecen al pool correcto.

**Acceptance Scenarios**:

1. **Scenario**: Recompensa de cartas del pool de la criatura
   - **Given** el jugador controla a "Prota & Pikachu" y vence un combate
   - **When** se muestra la selección de recompensa (3 cartas)
   - **Then** las 3 cartas ofrecidas pertenecen al pool de "Pikachu" (tipo eléctrico o comunes)

2. **Scenario**: Cartas exclusivas de criatura
   - **Given** "Electivire" tiene la carta exclusiva "Giga Impact"
   - **When** se revisa el pool de cartas de cualquier otra criatura
   - **Then** "Giga Impact" no aparece en ningún otro pool

3. **Scenario**: Pool de cartas heredado tras evolución
   - **Given** "Pikachu" evoluciona a "Raichu"
   - **When** se genera el nuevo pool de cartas
   - **Then** el pool de "Raichu" contiene todas las cartas que tenía "Pikachu" más nuevas cartas exclusivas de "Raichu"

---

### User Story 3 - Evolución de Criaturas (Priority: P1)

Las criaturas evolucionan al alcanzar ciertos umbrales de nivel del personaje Y obtener materiales específicos de la historia. La evolución es permanente: cambia el sprite de la criatura, sus stats base, y expande su pool de cartas con nuevas opciones. Algunas criaturas tienen evoluciones ramificadas (elección del jugador).

**Why this priority**: La evolución es la progresión vertical del personaje y un pilar de la franquicia. Bloquea contenido (cartas) detrás de progreso de historia.

**Independent Test**: Se puede testear seteando manualmente el nivel de un personaje y otorgando el material requerido, y verificando que la evolución se dispara correctamente.

**Acceptance Scenarios**:

1. **Scenario**: Evolución al alcanzar umbral de nivel con material
   - **Given** "Charmander" está a nivel 16 (umbral: 16) y el jugador tiene "Piedra Fuego" en inventario
   - **When** se cumplen ambas condiciones tras un combate o evento de historia
   - **Then** se reproduce animación de evolución, Charmander → Charmeleon, y el pool de cartas se expande

2. **Scenario**: Evolución bloqueada sin material
   - **Given** "Charmander" está a nivel 16 pero el jugador NO tiene "Piedra Fuego"
   - **When** el personaje alcanza el nivel en combate
   - **Then** no ocurre evolución; se muestra un mensaje: "Charmander quiere evolucionar pero falta Piedra Fuego"

3. **Scenario**: Evolución ramificada con elección
   - **Given** "Eevee" alcanza nivel de evolución y el jugador tiene múltiples materiales compatibles
   - **When** se dispara el evento de evolución
   - **Then** se presentan las opciones disponibles (ej. Piedra Agua → Vaporeon, Piedra Fuego → Flareon) y el jugador elige

4. **Scenario**: Evolución por historia (sin nivel)
   - **Given** cierto punto de la historia otorga evolución automática a la criatura del protagonista
   - **When** se completa la escena/evento
   - **Then** la criatura evoluciona independientemente del nivel

---

### User Story 4 - Composición y Gestión del Equipo (Priority: P2)

El jugador forma un equipo de exactamente 3 personajes para el combate. En modo Historia, el equipo se define por la narrativa (personajes que acompañan al protagonista en ese momento de la historia). En modo Roguelike, el jugador elige 1 personaje principal al inicio; los otros 2 slots se llenan durante la run (encuentros de aliados, eventos).

**Why this priority**: El sistema de 3 personajes añade profundidad táctica, pero primero se necesita que el combate con 1 personaje funcione.

**Independent Test**: Se puede testear creando una escena de selección de equipo con 3 slots y verificando que los 3 personajes aparecen en combate con sus respectivos mazos activos.

**Acceptance Scenarios**:

1. **Scenario**: Selección de equipo de 3 en modo Roguelike
   - **Given** el jugador inicia una run y elige protagonista "Prota & Pikachu"
   - **When** encuentra un nodo de "Aliado" y recluta a "Personaje 2 & Charmander"
   - **Then** el equipo ahora tiene 2 personajes; el tercer slot se llena con otro encuentro de aliado

2. **Scenario**: Equipo fijo en modo Historia
   - **Given** el capítulo 3 requiere que el protagonista viaje con "Personaje A" y "Personaje B"
   - **When** el jugador entra en combate en ese capítulo
   - **Then** el equipo está compuesto exactamente por: Protagonista, Personaje A y Personaje B

3. **Scenario**: Pérdida de un miembro del equipo en combate
   - **Given** los 3 personajes están en combate y el personaje 2 llega a 0 HP
   - **When** se resuelve el KO
   - **Then** ese personaje queda inactivo el resto del combate; los otros 2 continúan (sus mazos, energía y bloqueo son independientes)

4. **Scenario**: Mazos independientes por personaje
   - **Given** el equipo tiene 3 personajes en combate
   - **When** es el turno del jugador
   - **Then** cada personaje tiene su propia mano, energía y pila de descarte independientes; el jugador puede jugar cartas de cualquier personaje activo

---

### User Story 5 - Cambio de Criatura del Protagonista (Priority: P2)

En puntos específicos de la historia, el protagonista puede cambiar de criatura (o su criatura evoluciona a una forma con diferente identidad mecánica). Esto se representa como un cambio de entidad en código: "Prota & Pikachu" → "Prota & Raichu". El mazo se actualiza al pool de la nueva criatura/evolución.

**Why this priority**: Representa el crecimiento del protagonista y desbloquea nuevo contenido, pero las mecánicas base de criatura + cartas deben funcionar primero.

**Independent Test**: Se puede testear forzando un trigger de cambio de criatura en una escena de prueba y verificando que el personaje ahora usa el nuevo pool de cartas.

**Acceptance Scenarios**:

1. **Scenario**: Cambio de criatura por evento de historia
   - **Given** el protagonista está en "Prota & Pikachu"
   - **When** ocurre el evento de historia "Regalo de Profesor" que otorga "Piedra Trueno"
   - **Then** Pikachu evoluciona a Raichu; la entidad pasa a ser "Prota & Raichu" con nuevo pool de cartas

2. **Scenario**: Mazo tras evolución conserva cartas comunes
   - **Given** "Prota & Pikachu" tiene cartas obtenidas durante la historia
   - **When** evoluciona a "Prota & Raichu"
    - **Then** se conservan las cartas comunes y se reemplazan las exclusivas de Pikachu por las de Raichu en el mazo

3. **Scenario**: Versiones alternativas en Roguelike
   - **Given** el jugador desbloqueó "Prota & Pikachu" y "Prota & Charmander" vía meta-progresión
   - **When** inicia una nueva run roguelike
   - **Then** ambas versiones aparecen como personajes seleccionables por separado

---

### Edge Cases

- **Cartas al evolucionar criatura**: Se conservan las cartas comunes y se reemplazan las exclusivas de la forma anterior por las de la nueva forma (ver FR-013).
- **Balance entre criaturas evolucionadas y no evolucionadas**: El desbalance es parte del diseño del juego. No se aplica nivelación artificial.
- **Cambio de criatura en no-protagonistas**: No es posible. Solo el protagonista puede rotar de criatura (ver FR-013).
- **Cambio de criatura del protagonista y afinidades**: Las afinidades con personajes se mantienen intactas al cambiar de criatura.
- **Muerte permanente de personaje del equipo**: Los personajes solo pueden morir durante el modo Historia, y únicamente si su muerte es parte de la narrativa. En Roguelike no hay muerte permanente de personajes.
- **Evoluciones ramificadas reversibles**: No, las evoluciones ramificadas son permanentes e irreversibles.
- **Materiales de evolución**: No son consumibles y no se pierden al morir. Una vez obtenidos, permanecen disponibles permanentemente.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Cada personaje jugable DEBE tener exactamente UNA (1) criatura asignada. La combinación Personaje + Criatura define una entidad de personaje única en código.
- **FR-002**: Cada criatura DEBE definir un pool de cartas compuesto por: cartas comunes (compartidas entre criaturas del mismo tipo o globales) y cartas exclusivas (únicas de esa criatura).
- **FR-003**: La criatura asignada a un personaje DETERMINA qué cartas aparecen en su mazo inicial, recompensas post-combate, y tienda.
- **FR-004**: El sistema DEBE soportar evolución de criaturas gatillada por: (a) nivel del personaje + material requerido, o (b) evento de historia.
- **FR-005**: La evolución DEBE cambiar permanentemente la entidad del personaje: actualizar sprite de criatura, expandir pool de cartas, y modificar stats base.
- **FR-006**: El sistema DEBE soportar evoluciones ramificadas donde el jugador elige entre múltiples opciones si tiene los materiales requeridos.
- **FR-007**: El equipo de combate DEBE estar compuesto por exactamente 3 personajes.
- **FR-008**: En combate, cada personaje del equipo DEBE tener su propio mazo, mano, pila de descarte, energía y bloqueo, independientes de los demás.
- **FR-009**: En modo Historia, el equipo DEBE ser determinado por la narrativa (personajes fijos según el capítulo).
- **FR-010**: En modo Roguelike, el jugador DEBE seleccionar 1 personaje al inicio de la run y poder reclutar aliados para los otros 2 slots durante la run.
- **FR-011**: El protagonista DEBE poder cambiar de criatura SOLO en puntos específicos de la historia (evolución o evento narrativo), no libremente.
- **FR-012**: El sistema DEBE proveer una pantalla de visualización de criatura donde se vean: sprite, nivel, stats, evoluciones disponibles, y pool de cartas asociado.

- **FR-013**: El sistema DEBE permitir que SOLO el protagonista pueda rotar entre criaturas previamente obtenidas. Todos los demás personajes tienen UNA (1) criatura fija e inmutable (excepto evolución).
- **FR-014**: El sistema DEBE soportar mega-evoluciones y formas temporales durante el combate (además de evoluciones permanentes).
- **FR-015**: El sistema NO DEBE soportar breed ni fusión de criaturas.

### Key Entities

- **CharacterData (Datos de Personaje)**: Resource unico que define un personaje jugable con su criatura. Fusiona identidad + stats + pool + evoluciones en un solo `.tres`. Atributos: `id` (String, ej: "prota_pikachu"), `display_name`, `character_id` (String, ej: "protagonist", agrupa versiones del mismo personaje), `is_protagonist`, `character_sprite`, `creature_sprite`, `types[]`, `base_hp`, `base_atk`, `base_def`, `base_spd`, `move_pool_ids[]` (IDs de cartas), `evolution_options[]` (Array[Dictionary] con `{dest_id, required_level, required_material_id, evo_type}` — LEVEL/STORY/BRANCHED).
- **EvolutionMaterial (Material de Evolución)**: Resource `.tres` necesario para evolucionar. Atributos: `id`, `display_name`, `description`, `sprite_path`. No se consume al usarse; se obtiene en la historia.
- **Team (Equipo)**: Composicion de 3 CharacterData para combate. Atributos: `members` (array[3] de `CharacterData`), `active_index` (int).
- **CharacterInstance (Instancia de Personaje)**: Estado runtime de un personaje durante el juego. Atributos: `current_character_id` (String, cambia al evolucionar), `level`, `xp`, `evolution_history` (Array[String] de character_ids recorridos). Referencia al `CharacterData` via `character_database.get_character()`.
- **CharacterRoster (Roster)**: Registro de todos los `CharacterData` desbloqueados por el jugador (via historia o meta-progresion). Metodos: `unlock(character_id)`, `get_unlocked() → Array[CharacterData]`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las cartas en el mazo de un personaje pertenecen al pool definido por su criatura, verificado con prueba automatizada para todos los personajes.
- **SC-002**: La evolución de una criatura (animación + cambio de sprites + actualización de pool) se completa en menos de 5 segundos.
- **SC-003**: Al menos 10 criaturas tienen pools de cartas únicos con un mínimo de 5 cartas exclusivas cada una.
- **SC-004**: El sistema de equipo de 3 personajes en combate funciona sin errores de estado (mazos mezclados, energía compartida) en el 100% de los escenarios de prueba.
- **SC-005**: Los jugadores pueden identificar correctamente qué criatura tiene cada personaje del equipo en la UI de combate en menos de 2 segundos (prueba de usabilidad con al menos 5 participantes).
- **SC-006**: El sistema soporta al menos 3 evoluciones por criatura (2 ramificadas + 1 lineal) para el 50% del roster de criaturas.
- **SC-007**: El cambio de criatura del protagonista por evento de historia preserva correctamente el estado de relación y afinidades con personajes en el 100% de los casos.
