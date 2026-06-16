# Feature Specification: Catálogo de Enemigos y Encuentros

**Created**: 2026-06-16

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Definición de Entrenadores Enemigos (Priority: P1)

El sistema debe tener un catálogo de entrenadores enemigos definidos por datos. Cada entrenador enemigo tiene: nombre, clase (Entrenador, Élite, Líder de Gimnasio), un equipo de 1-3 Pokémon (cada uno con criatura, nivel, movimientos, y patrón de IA), y recompensas al ser vencido (Pokédólares, posibilidad de carta). Estos datos son usados tanto por el sistema de combate como por el generador de mapas.

**Why this priority**: Sin datos de enemigos no hay combate posible. Es el prerequisito para cualquier encuentro.

**Independent Test**: Se puede testear creando un entrenador enemigo con 1 Pokémon, iniciando un combate de prueba y verificando que el enemigo aparece con los datos correctos (nombre, sprite, HP, movimientos).

**Acceptance Scenarios**:

1. **Scenario**: Cargar entrenador enemigo desde datos
   - **Given** existe un recurso `.tres` para el entrenador "Joven Pérez" (clase Entrenador, equipo: 1 Rattata nivel 3)
   - **When** se inicia un combate contra ese entrenador
   - **Then** el sistema carga nombre, clase, sprites y los datos completos del Rattata (HP, movimientos, patrón IA)

2. **Scenario**: Entrenador Élite con equipo de 2 Pokémon
   - **Given** "Entrenador Élite Bruno" tiene 2 Pokémon en su equipo
   - **When** se inicia el combate
   - **Then** ambos Pokémon aparecen en el campo enemigo y el primero es el activo; el segundo entra al ser debilitado el primero

3. **Scenario**: Líder de Gimnasio con estadísticas aumentadas
   - **Given** "Líder Brock" tiene un Geodude nivel 7 con HP y stats escalados
   - **When** se inicia el combate
   - **Then** el Geodude tiene los stats correctamente escalados por su nivel de Líder

---

### User Story 2 - Patrones de IA Enemiga (Priority: P1)

Cada Pokémon enemigo sigue un patrón de IA que determina qué movimiento usará cada turno. Los patrones disponibles son: Fijo (secuencia predefinida), Aleatorio (elige al azar de su pool), Reactivo (elige según estado del combate: prioriza curarse si HP < 50%, usa buff si no tiene, ataca en caso contrario). La intención del enemigo se muestra al jugador antes de que actúe.

**Why this priority**: Sin IA los combates no tienen comportamiento enemigo. Es parte del core loop.

**Independent Test**: Se puede testear creando un enemigo con patrón fijo de 3 movimientos y verificando que ejecuta la secuencia exacta en 3 turnos consecutivos.

**Acceptance Scenarios**:

1. **Scenario**: Patrón fijo
   - **Given** un Pokémon enemigo con patrón fijo: [Atacar, Defender, Atacar]
   - **When** transcurren 3 turnos enemigos
   - **Then** ejecuta exactamente: Turno 1 = Ataque, Turno 2 = Defensa, Turno 3 = Ataque (se repite si hay más turnos)

2. **Scenario**: Patrón reactivo - prioridad curarse
   - **Given** un Pokémon enemigo con patrón reactivo y HP < 50%
   - **When** es su turno y tiene un movimiento de curación en su pool
   - **Then** usa el movimiento de curación en lugar de atacar

3. **Scenario**: Intención visible antes del turno enemigo
   - **Given** es el turno del jugador y el enemigo ya determinó su intención
   - **When** el jugador observa el HUD
   - **Then** se muestra sobre el enemigo: icono + nombre del movimiento + valor estimado (ej. "Placaje → 15 daño")

---

### User Story 3 - Pools de Encuentros por Zona (Priority: P2)

Cada zona del overworld y cada acto del mapa roguelike tienen un pool de entrenadores enemigos que pueden aparecer. Los pools definen qué entrenadores están disponibles y con qué probabilidad (pesos). Los encuentros aleatorios y los nodos de Entrenador en el mapa roguelike seleccionan enemigos de estos pools.

**Why this priority**: Sin pools no hay variedad de encuentros. Pero se puede testear combate con enemigos fijos mientras tanto.

**Independent Test**: Se puede testear definiendo un pool con 3 entrenadores y pesos, ejecutando 100 selecciones aleatorias y verificando que la distribución coincide con los pesos (±10%).

**Acceptance Scenarios**:

1. **Scenario**: Pool de zona hostil
   - **Given** la "Ruta 1" tiene un pool: [Joven Pérez (peso 5), Excursionista (peso 3), Pescador (peso 2)]
   - **When** se dispara un encuentro aleatorio en la Ruta 1
   - **Then** el enemigo se selecciona aleatoriamente respetando los pesos (Joven Pérez ≈50%, Excursionista ≈30%, Pescador ≈20%)

2. **Scenario**: Pool de acto en roguelike
   - **Given** el Acto 1 del mapa roguelike tiene pools separados para Entrenador normal, Élite, y Líder de Gimnasio
   - **When** el jugador llega a un nodo de Entrenador
   - **Then** el enemigo se selecciona SOLO del pool de Entrenadores normales del Acto 1

3. **Scenario**: Zona segura sin pool
   - **Given** una zona tipo "Pueblo" marcada como segura
   - **When** el jugador camina por ella
   - **Then** no se generan encuentros aleatorios (el pool puede ser null o vacío)

---

### User Story 4 - Escalado de Dificultad (Priority: P3)

Los enemigos escalan sus estadísticas según el contexto: en modo Historia, los Líderes de Gimnasio tienen nivel fijo; en modo Roguelike, los enemigos escalan según el acto (Acto 1 = base, Acto 2 = +30% stats, Acto 3 = +60% stats). Los niveles de Ascensión añaden modificadores adicionales.

**Why this priority**: El escalado es necesario para balance pero el combate es jugable con stats fijos inicialmente.

**Independent Test**: Se puede testear creando un mismo entrenador en Acto 1 y Acto 3 y verificando que sus stats en Acto 3 son exactamente +60% de los de Acto 1.

**Acceptance Scenarios**:

1. **Scenario**: Escalado por acto
   - **Given** "Entrenador Élite Bruno" tiene HP base 40 en su definición
   - **When** aparece en Acto 2 del mapa roguelike
   - **Then** su HP real es 52 (40 × 1.30)

2. **Scenario**: Escalado por Ascensión
   - **Given** el jugador está en Ascensión nivel 3 (enemigos +15% HP)
   - **When** combate contra un entrenador en Acto 1
   - **Then** el HP del enemigo es base × 1.0 (acto 1) × 1.15 (ascensión)

---

### Edge Cases

- **Pool de zona vacío o no definido**: No se generan encuentros aleatorios en esa zona.
- **Entrenador sin movimientos definidos**: El sistema asigna automáticamente "Placaje" (movimiento básico) como fallback. No debe crashear.
- **Niveles de enemigos en mapa procedural**: El nivel base del enemigo se multiplica por el acto. Los Líderes de Gimnasio siempre tienen +2 niveles sobre el promedio del acto.
- **Múltiples Pokémon enemigos activos a la vez**: No en el diseño actual. El combate es 1 enemigo activo a la vez, con reemplazo al ser debilitado.
- **Enemigo con Pokémon que no tiene movimientos de ataque**: La IA prioriza movimientos de estado/buff si no tiene ataques. Si no tiene ningún movimiento usable, pasa el turno (struggle).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE tener un catálogo de entrenadores enemigos definido como Resources (`.tres`), con al menos 15 entrenadores distintos para la versión inicial.
- **FR-002**: Cada entrenador enemigo DEBE definir: nombre, clase (Entrenador / Élite / Líder), sprite_path, equipo (array de 1-3 EnemyPokemon), recompensa_base_pokedollars, y pool de posibles cartas de recompensa.
- **FR-003**: Cada EnemyPokemon DEBE definir: character_id (referencia a un CharacterData), nivel, HP base (calculado del nivel), movimientos (array de 2-4 move_ids), patron de IA (FIXED / RANDOM / REACTIVE), y secuencia de movimientos (si patron FIXED).
- **FR-004**: El sistema DEBE soportar tres patrones de IA: FIXED (secuencia predefinida cíclica), RANDOM (elige movimiento al azar del pool cada turno), REACTIVE (elige según condiciones: HP < 50% → curar; sin buffs → buff; else → ataque más fuerte disponible).
- **FR-005**: El sistema DEBE mostrar la intención del enemigo (nombre del movimiento + efecto estimado) ANTES de que el jugador actúe en su turno.
- **FR-006**: El sistema DEBE tener pools de encuentros por zona del overworld (`encounter_pools.tres`) y por acto del mapa roguelike, con entrenadores y pesos configurables.
- **FR-007**: El sistema DEBE seleccionar enemigos de los pools usando los pesos definidos (selección ponderada aleatoria).
- **FR-008**: El sistema DEBE escalar las estadísticas de los enemigos según el acto (Acto 1: ×1.0, Acto 2: ×1.30, Acto 3: ×1.60) en modo Roguelike.
- **FR-009**: El sistema DEBE aplicar modificadores de Ascensión sobre los stats base escalados por acto (multiplicadores acumulativos).
- **FR-010**: Los Líderes de Gimnasio DEBEN tener nivel fijo en modo Historia y nivel = promedio_acto + 2 en modo Roguelike.
- **FR-011**: El sistema DEBE validar que todo entrenador cargado tiene al menos 1 Pokémon con al menos 1 movimiento; si no, asignar fallbacks (Placaje).

### Key Entities

- **EnemyTrainerData (Datos de Entrenador Enemigo)**: Resource (`.tres`) que define un entrenador enemigo. Atributos: `id`, `display_name`, `class` (TRAINER/ELITE/LEADER), `sprite_path`, `team` (array[1..3] de EnemyPokemonData), `reward_pokedollars` (int), `reward_card_pool` (array de move_ids que pueden aparecer como recompensa).
- **EnemyPokemonData (Datos de Pokémon Enemigo)**: Sub-recurso dentro de EnemyTrainerData. Atributos: `character_id` (referencia a CharacterData), `level` (int), `base_hp` (int, calculado de stats + nivel), `move_ids` (array[2..4] de strings), `ai_pattern` (enum: FIXED/RANDOM/REACTIVE), `fixed_sequence` (array de move_ids, solo si patrón FIXED).
- **EncounterPool (Pool de Encuentros)**: Resource (`.tres`) que asigna entrenadores a una zona o acto. Atributos: `pool_id`, `entries` (array de {trainer_id: String, weight: float}). Método: `pick_random() → EnemyTrainerData` usando selección ponderada.
- **EncounterPoolSet (Conjunto de Pools)**: Resource que agrupa pools por tipo de nodo para un acto roguelike. Atributos: `act_number`, `trainer_pool` (EncounterPool), `elite_pool` (EncounterPool), `leader_trainer` (EnemyTrainerData, fijo, no aleatorio).
- **EnemyAIState (Estado de IA en Combate)**: Estado runtime de la IA enemiga durante un combate. Atributos: `current_pokemon_index`, `fixed_sequence_position` (int, para patrón FIXED), `current_intention` (Intention). Referencia al EnemyTrainerData original.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El catálogo contiene al menos 15 entrenadores enemigos definidos, cada uno con al menos 1 Pokémon y 2 movimientos.
- **SC-002**: El 100% de las intenciones enemigas se muestran correctamente en el HUD antes del turno del jugador (prueba automatizada con todos los patrones de IA).
- **SC-003**: La selección ponderada de pools respeta los pesos configurados con ±10% de margen en una muestra de 1000 selecciones.
- **SC-004**: El escalado de stats por acto aplica correctamente los multiplicadores (×1.0, ×1.30, ×1.60) en el 100% de los casos.
- **SC-005**: El sistema de fallback asigna "Placaje" automáticamente si un entrenador se define sin movimientos en su pool, sin causar crash.
