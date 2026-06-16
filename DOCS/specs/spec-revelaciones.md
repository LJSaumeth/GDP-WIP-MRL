# Feature Specification: Revelaciones (Variantes de Cartas)

**Created**: 2026-06-14

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Demonstrated to users independently
-->

### User Story 1 - Pool de Revelaciones por Carta (Priority: P1)

Cada carta exclusiva de criatura y cada carta obtenida por evolución tiene asociada una **pool de Revelaciones**: un conjunto de variantes de efecto que transforman el comportamiento base de la carta. Una Revelación modifica uno o más parámetros del movimiento (daño, coste, tipo elemental, efectos secundarios, condiciones de activación, etc.). Las cartas comunes no tienen Revelaciones.

**Why this priority**: Las Revelaciones son lo que hace que las cartas exclusivas y de evolución se sientan únicas y moldeables. Sin el pool definido, el sistema de selección (US2) no tiene datos.

**Independent Test**: Se puede testear definiendo una carta exclusiva de prueba con un pool de 3 Revelaciones y verificando que los datos se cargan correctamente desde los recursos de la criatura.

**Acceptance Scenarios**:

1. **Scenario**: Carta exclusiva con pool de Revelaciones
   - **Given** la carta exclusiva "Rayo Fulminante" de Pikachu tiene un pool de 4 Revelaciones
   - **When** se inspeccionan los datos de la carta en el editor o en debug
   - **Then** la carta referencia su pool de Revelaciones: [Carga Paralizante, Rayo en Cadena, Sobrevoltaje, Descarga Estática]

2. **Scenario**: Carta común sin Revelaciones
   - **Given** "Placaje" es una carta común compartida entre criaturas
   - **When** se inspeccionan sus datos
   - **Then** no tiene pool de Revelaciones (campo vacío o null)

3. **Scenario**: Carta de evolución con Revelaciones
   - **Given** "Electrocañón" es una carta que se añade al evolucionar Pikachu → Raichu
   - **When** se inspeccionan sus datos
   - **Then** tiene su propio pool de Revelaciones independiente

---

### User Story 2 - Selección de Revelación en Roguelike (Priority: P1)

Durante una run Roguelike, al obtener una carta exclusiva o de evolución como recompensa (post-combate, tienda, evento), el sistema presenta 3 Revelaciones aleatorias del pool de esa carta. El jugador elige UNA (1) Revelación, que define la variante de la carta que se añade a su mazo. Una vez elegida, no puede cambiarse durante la run.

**Why this priority**: Es el loop central de las Revelaciones. La selección es el momento de decisión táctica que hace cada run única.

**Independent Test**: Se puede testear simulando una pantalla de recompensa que ofrece una carta exclusiva + 3 Revelaciones, verificando que el jugador elige una y la carta resultante tiene los parámetros modificados.

**Acceptance Scenarios**:

1. **Scenario**: Oferta de 3 Revelaciones al obtener carta exclusiva
   - **Given** el jugador derrota un Entrenador Élite y la recompensa incluye la carta exclusiva "Llamarada"
   - **When** se muestra la pantalla de selección
   - **Then** se presentan 3 Revelaciones aleatorias del pool de "Llamarada", cada una con nombre, descripción del efecto modificado, y vista previa del cambio de stats

2. **Scenario**: Jugador elige una Revelación
   - **Given** se muestran 3 Revelaciones para "Llamarada": [Quemadura Garantizada, Coste Reducido, Daño en Área]
   - **When** el jugador selecciona "Coste Reducido"
   - **Then** la carta "Llamarada (Coste Reducido)" se añade al mazo con su coste de energía reducido en 1; las otras 2 Revelaciones se descartan

3. **Scenario**: Revelación fija durante la run
   - **Given** el jugador tiene "Llamarada (Coste Reducido)" en su mazo
   - **When** intenta modificar o cambiar la Revelación de esa carta durante la run
   - **Then** no es posible; la Revelación es permanente para esa instancia de la carta en esa run

4. **Scenario**: Skip de Revelación
   - **Given** el jugador no quiere elegir ninguna Revelación para la carta ofrecida
   - **When** selecciona "Sin Revelación" o cierra la pantalla
   - **Then** la carta se añade al mazo en su versión base, sin modificaciones de Revelación

5. **Scenario**: Dos copias de la misma carta con distinta Revelación
   - **Given** el jugador ya tiene "Llamarada (Coste Reducido)" y obtiene otra copia de "Llamarada"
   - **When** elige "Quemadura Garantizada" en la nueva selección
   - **Then** el mazo ahora contiene dos copias de "Llamarada", cada una con su propia Revelación; se tratan como cartas independientes

---

### User Story 3 - Efecto de la Revelación en Combate (Priority: P2)

La Revelación elegida altera el comportamiento de la carta durante el combate. Los cambios pueden incluir: modificación de daño base, cambio de coste de energía, adición o modificación de efectos secundarios (estados alterados, buffs, debuffs), cambio de tipo elemental, o conversión de single-target a multi-target. La UI de la carta en mano refleja visualmente la Revelación activa.

**Why this priority**: Las Revelaciones necesitan manifestarse en combate para tener impacto en el gameplay. Pero primero se necesita que la selección (US2) funcione.

**Independent Test**: Se puede testear creando una carta con Revelación aplicada, jugándola en combate y verificando que el efecto modificado se resuelve correctamente.

**Acceptance Scenarios**:

1. **Scenario**: Revelación modifica el daño base
   - **Given** el jugador tiene "Llamarada (Sobrecalentamiento)" con Revelación: +10 daño, -1 Defensa propia
   - **When** usa la carta en combate
   - **Then** el daño infligido es daño_base + 10, y el Pokémon usuario recibe -1 Defensa

2. **Scenario**: Revelación cambia el tipo elemental
   - **Given** "Rayo Hielo" de Glaceon tiene Revelación "Rayo Escarcha" que cambia su tipo de Hielo a Hielo + Agua
   - **When** se usa contra un Pokémon de tipo Fuego
   - **Then** el multiplicador de tipo se calcula usando ambos tipos (doble type advantage si aplica)

3. **Scenario**: Revelación añade un efecto de estado
   - **Given** "Impactrueno" tiene Revelación "Onda Paralizante" que añade 50% de Paralizar
   - **When** se usa en combate
   - **Then** tras resolver el daño, se tira el 50% de probabilidad de aplicar Parálisis al objetivo

4. **Scenario**: UI de la carta refleja la Revelación
   - **Given** el jugador tiene "Llamarada (Coste Reducido)" en la mano
   - **When** observa la carta
   - **Then** el coste mostrado es el modificado (ej: 2 en lugar de 3), y un indicador visual (brillo, ícono, borde especial) distingue que es una carta con Revelación activa

---

### User Story 4 - Pool de Revelaciones por Carta (Priority: P2)

El pool de Revelaciones de cada carta tiene entre 4 y 8 opciones. De este pool, se seleccionan 3 al azar para ofrecer al jugador en cada instancia de recompensa. La selección es sin reposición dentro de una misma oferta (no se repite la misma Revelación 2 veces en las 3 opciones), pero sí puede repetirse entre distintas ofertas de la misma carta en runs diferentes.

**Why this priority**: Define las reglas de generación procedural. Sin esto, el sistema de selección no tiene variabilidad real.

**Independent Test**: Se puede testear ejecutando la selección de Revelaciones 100 veces para una misma carta y verificando que: (a) nunca se repite una Revelación en la misma oferta de 3, (b) cada Revelación del pool aparece aproximadamente el mismo número de veces (distribución uniforme).

**Acceptance Scenarios**:

1. **Scenario**: Pool mínimo de 4 Revelaciones
   - **Given** una carta exclusiva nueva
   - **When** se define su pool de Revelaciones
   - **Then** debe contener al menos 4 Revelaciones distintas

2. **Scenario**: 3 Revelaciones sin repetición
   - **Given** el pool de "Llamarada" tiene 6 Revelaciones
   - **When** se generan las 3 opciones para la pantalla de selección
   - **Then** las 3 Revelaciones mostradas son distintas entre sí

3. **Scenario**: Pool pequeño (<3 Revelaciones)
   - **Given** una carta tiene solo 2 Revelaciones definidas en su pool (error de diseño o caso legacy)
   - **When** se intenta generar la oferta de 3
   - **Then** se muestran las 2 disponibles; el tercer slot aparece vacío o se ofrece "Sin Revelación"

4. **Scenario**: Distribución de selección es justa
   - **Given** un pool de 6 Revelaciones
   - **When** se ejecutan 300 selecciones (100 ofertas × 3 slots)
   - **Then** cada Revelación aparece aproximadamente el mismo número de veces (±10% de variación máxima)

---

### Edge Cases

- **Carta exclusiva sin Revelaciones definidas**: La carta se comporta normalmente (versión base). No se muestra pantalla de selección de Revelación al obtenerla.
- **Revelación que modifica coste de energía por debajo de 0**: El coste mínimo es 0. Revelaciones que reduzcan el coste no pueden bajarlo de 0.
- **Revelación hace la carta objetivamente peor**: Es válido. Algunas Revelaciones pueden tener trade-offs (ej: +daño pero +coste). El jugador siempre puede elegir "Sin Revelación".
- **Dos Revelaciones con efecto contradictorio en el pool**: Son entradas separadas y válidas. La selección del jugador resuelve la contradicción.
- **Revelación en cartas con múltiples efectos**: La Revelación modifica solo los parámetros indicados; el resto del comportamiento de la carta se mantiene igual.
- **Revelación y Furor**: Una Revelación podría añadir un efecto que interactúe con la barra de furor (ej: genera +1 furor adicional al usarse). Esto es válido y deseable como sinergia.
- **Revelación y estado Mega/G-Max/Tera**: Si una Revelación cambia el tipo elemental de una carta y el Pokémon está Teracrestalizado, el tipo Tera tiene prioridad sobre el tipo de la Revelación.
- **Persistencia de Revelación entre runs**: Las Revelaciones elegidas NO persisten entre runs Roguelike. Cada run es independiente.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE asociar un pool de Revelaciones a cada carta exclusiva de criatura y a cada carta obtenida por evolución.
- **FR-002**: Las cartas comunes NO DEBEN tener pool de Revelaciones.
- **FR-003**: Cada pool de Revelaciones DEBE contener entre 4 y 8 Revelaciones distintas por carta.
- **FR-004**: Una Revelación DEBE modificar al menos un parámetro de la carta: daño, coste de energía, tipo elemental, efectos secundarios, número de objetivos, o condiciones de activación.
- **FR-005**: Al obtener una carta con Revelaciones (recompensa, tienda, evento) en modo Roguelike, el sistema DEBE seleccionar 3 Revelaciones aleatorias sin repetición del pool y ofrecerlas al jugador.
- **FR-006**: El jugador DEBE poder elegir UNA (1) Revelación de las 3 ofrecidas, o elegir "Sin Revelación" para mantener la carta en su versión base.
- **FR-007**: Una vez elegida, la Revelación DEBE ser permanente para esa instancia de la carta durante el resto de la run. No puede cambiarse ni eliminarse.
- **FR-008**: Dos copias de la misma carta con distinta Revelación DEBEN tratarse como cartas independientes en el mazo.
- **FR-009**: La UI de la carta en mano DEBE reflejar visualmente la Revelación activa: valores modificados (daño, coste), indicador visual distintivo, y tooltip con el nombre y descripción de la Revelación.
- **FR-010**: El efecto de la Revelación DEBE aplicarse en el momento de resolver la carta en combate, siguiendo el mismo pipeline de resolución de movimientos (`move_resolver.gd`).
- **FR-011**: El coste de energía de una carta con Revelación NUNCA DEBE ser menor que 0.
- **FR-012**: El sistema DEBE soportar Revelaciones con trade-offs (ej: +daño pero +coste, +efecto pero -daño).

### Key Entities

- **Revelation (Revelación)**: Variante de una carta que modifica su efecto. Atributos: `id`, `name`, `description`, `modifiers` (dict de parámetros modificados: `damage`, `cost`, `elemental_type`, `secondary_effects[]`, `target_type`, `conditions[]`, `furor_generation`).
- **RevelationPool (Pool de Revelaciones)**: Conjunto de Revelaciones asociadas a una carta. Atributos: `card_id`, `revelations` (array[Revelation], 4-8 elementos). Método: `draw_random(n=3) → array[Revelation]` — selección sin repetición.
- **RevelationCard (Carta con Revelación)**: Instancia de una carta con una Revelación aplicada. Atributos: `base_card_id`, `revelation_id`, `resolved_stats` (valores finales tras aplicar modificadores de la Revelación). Se comporta como una carta normal en el mazo, mano y descarte.
- **RevelationSelection (Selección de Revelación)**: Pantalla de elección. Atributos: `card`, `offered_revelations` (array[3 Revelations]), `selected_index` o `skipped`. Se presenta como parte del flujo de recompensa.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las cartas exclusivas y de evolución del juego tienen un pool de Revelaciones con al menos 4 opciones definidas.
- **SC-002**: La selección de 3 Revelaciones nunca repite la misma Revelación en una misma oferta, verificado en 1000 iteraciones de prueba.
- **SC-003**: La UI de selección de Revelación se completa en 3 clics o menos (ver Revelaciones → elegir una → confirmar).
- **SC-004**: La carta con Revelación refleja correctamente sus stats modificados en la mano, tooltip y resolución de combate en el 100% de los casos de prueba.
- **SC-005**: En playtest, al menos el 60% de los jugadores elige una Revelación (no "Sin Revelación") cuando se les ofrece, indicando que las opciones son atractivas.
- **SC-006**: Jugadores reportan que las Revelaciones hacen que obtener una copia duplicada de una carta exclusiva se sienta diferente a la primera vez, en al menos el 80% de los casos (encuesta post-playtest).
